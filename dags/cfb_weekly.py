from airflow import DAG
from datetime import datetime, timedelta
from airflow.models import Variable
from airflow.providers.docker.operators.docker import DockerOperator
from airflow.operators.python import PythonOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
import os
import logging

default_args = {
    'owner': 'ecoop3345@gmail.com',
    'retries': 1,
    "retry_delay": timedelta(seconds=30),
}

def load_cfb_vars(**context):
    import logging
    cfb_config = Variable.get("CFB_CONFIG", default_var=None, deserialize_json=True)

    for key, val in cfb_config.items():
        logging.info(f"{key} variable value: {val}")

    # Push config to XCom for downstream tasks
    return cfb_config

sql_dir = "/opt/airflow/deps/cfb_weekly_processing"

with DAG(
    dag_id='cfb_weekly_processing',
    default_args={'owner': 'airflow'},
    start_date=datetime(2025, 10, 11),
    schedule=None,
    catchup=False,
) as dag:

    load_config = PythonOperator(
        task_id="load_config",
        python_callable=load_cfb_vars,
        provide_context=True,  # ensures XCom push
    )

    cfb_api_ingest = DockerOperator(
        task_id="cfb_api_ingest",
        image="ecoop3345/cfb-current-week:latest",
        docker_conn_id='docker_default',
        api_version="auto",
        auto_remove=True,
        force_pull=True,
        mount_tmp_dir=False,
        command="./app",
        docker_url="unix://var/run/docker.sock",
        network_mode="host",
        environment={
            "API_TOKEN": Variable.get("API_TOKEN", default_var=None),
            "DSN_STRING": Variable.get("DSN_STRING", default_var=None),
            "GET_FULL_SEASON": "{{ ti.xcom_pull(task_ids='load_config')['GET_FULL_SEASON'] }}",
            "GET_OFFSEASON": "{{ ti.xcom_pull(task_ids='load_config')['GET_OFFSEASON'] }}",
            "GET_ONE_OFFS": "{{ ti.xcom_pull(task_ids='load_config')['GET_ONE_OFFS'] }}",
            "GET_SEASON": "{{ ti.xcom_pull(task_ids='load_config')['GET_SEASON'] }}",
            "GET_WEEKLY": "{{ ti.xcom_pull(task_ids='load_config')['GET_WEEKLY'] }}",
            "INSERT_CAL": "{{ ti.xcom_pull(task_ids='load_config')['INSERT_CAL'] }}",
            "START_SEASON": "{{ ti.xcom_pull(task_ids='load_config')['START_SEASON'] }}",
            "END_SEASON": "{{ ti.xcom_pull(task_ids='load_config')['END_SEASON'] }}",
            "SEASON": "{{ ti.xcom_pull(task_ids='load_config')['SEASON'] }}",
            "PSCD": "{{ ti.xcom_pull(task_ids='load_config')['PSCD'] }}",
            "SEASON_TYPE": "{{ ti.xcom_pull(task_ids='load_config')['SEASON_TYPE'] }}",
            "WEEK": "{{ ti.xcom_pull(task_ids='load_config')['WEEK'] }}",
        },
    )

    load_config >> cfb_api_ingest

    if os.path.exists(sql_dir):
        sql_files = sorted([f for f in os.listdir(sql_dir) if f.endswith('.sql')])
        
        for sql_file in sql_files:
            sql_file_path = os.path.join(sql_dir, sql_file)
            with open(sql_file_path, 'r') as f:
                sql_content = f.read()

            task = SQLExecuteQueryOperator(
                task_id=f"cfb_load_{sql_file.replace('.sql', '')}",
                sql=sql_content,
                conn_id='mssql_default',
            )
            cfb_api_ingest >> task
    else:
        logging.warning(f"SQL directory not found: {sql_dir}")