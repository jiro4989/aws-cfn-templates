import os
import time
import json
from datetime import datetime, timedelta
from logging import getLogger, StreamHandler, DEBUG

import boto3
from botocore.config import Config

# 維持する日数
retaining_days = int(os.environ.get('RETAINING_DAYS', '7'))

# trueなら実際に削除を実行する
run = bool(os.environ.get('RUN', 'false'))

config = Config(
   retries = {
      'max_attempts': 3,
      'mode': 'standard'
   }
)

ec2 = boto3.client('ec2', config=config)
cfn = boto3.client('cloudformation', config=config)

service = 'delete_tmp_resource'
logger = getLogger(service)
handler = StreamHandler()
handler.setLevel(DEBUG)
logger.setLevel(DEBUG)
logger.addHandler(handler)
logger.propagate = False

def info(message, attributes = {}):
    """JSON形式で標準出力にログを出力する。

    attributes が存在した時、出力するJSONログに属性として後付する。
    オプション要素なので、無くても良い。

    Args:
        message (str): ログのメッセージ
        attributes (dict[str, str]): ログに追加したいオプショナルな属性
    """
    body = {
        'time': datetime.now().isoformat(),
        'level': 'info',
        'service': service,
        'message': message,
        'run': run,
        'retaining_days': retaining_days,
    }
    for k, v in attributes:
        body[k] = v
    logger.info(json.dumps(body))

def get_stack_information(tags):
    """タグ辞書からCloud Formation Stack属性を取得する。

    EC2の名前とCloud Formationのタグが1つでも足りない場合は
    Noneを返却する。呼び出し側ではNoneチェックをすること。

    Args:
        tags (list[dict[str, str]]): タグのリスト
    
    Returns:
        dict[str, str] or None: タグ情報
    """
    name = [x['Value'] for x in tags if x['Key'] == 'Name']
    if len(name) < 1:
        return None

    # これらのタグはCloud Formationで作成された時に自動で設定されるタグ
    logical_id = [x['Value'] for x in tags if x['Key'] == 'aws:cloudformation:logical-id']
    if len(logical_id) < 1:
        return None
    stack_id = [x['Value'] for x in tags if x['Key'] == 'aws:cloudformation:stack-id']
    if len(stack_id) < 1:
        return None
    stack_name = [x['Value'] for x in tags if x['Key'] == 'aws:cloudformation:stack-name']
    if len(stack_name) < 1:
        return None

    return {
        'ec2_name': name,
        'logical_id': logical_id,
        'stack_id': stack_id,
        'stack_name': stack_name,
    }

def fetch_deletion_targets():
    """削除対象のEC2のCloud Formation Stack情報を取得する。

    削除対象となる条件は以下の通り。
    1. 一時リソースである
    2. 自動削除対象である
    3. Cloud Formationで作成されたリソースである
    4. EC2が起動してから retaining_days 日以上経過している
    上記条件を満たしたEC2を削除対象として取得する。

    Returns:
        list[dict[str, str]]: 削除対象のCloud Formation Stack
    """
    deletion_targets = []

    # 自動削除タグが割り振られた一時リソースのみを取得
    instances = ec2.describe_instances(Filters=[
        {
            'Name': 'tag:resource_type',
            'Values': ['tmp'],
        },
        {
            'Name': 'tag:auto_deletion',
            'Values': ['true'],
        },
    ])
    for rev in instances['Reservations']:
        for instance in rev['Instances']:
            # Cloud Formationで作成されたインスタンスだけに絞り込む
            tags = instance['Tags']
            stack = get_stack_information(tags)
            if stack == None:
                continue

            # 起動して任意期間以上経過したインスタンスのみを削除対象とする
            launch_time = instance['LaunchTime']
            day = datetime.now() - timedelta(days=retaining_days)
            if day < launch_time:
                continue
            deletion_targets.append(stack)

    return deletion_targets

def delete_stacks(stacks, run):
    """Cloud Formation Stackを削除する。

    run がfalseの場合はDryRunする。ログ出力のみ実施して削除はしない。

    Args:
        stacks (list[dict[str, str]]): Cloud Formationのタグ情報
        run (bool): 実際に削除を実施するか否か。Trueの場合は削除する
    """
    for stack in stacks:
        info('delete stack', stack)
        if not run:
            info('skipped deletion', stack)
            continue
        cfn.delete_stack(
            StackName=stack['stack_name']
        )
        info('deleted stack', stack)
        time.sleep(0.5)
    info('deletion completed')

def lambda_handler(event, context):
    """Lambda関数のエントリーポイント。

    Args:
        event (Object): Event
        context (Object): Context
    """
    info('start script')
    stacks = fetch_deletion_targets()
    delete_stacks(stacks, run)
    info('end script')