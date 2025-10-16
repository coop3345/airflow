from airflow import DAG
from datetime import datetime, timedelta
from airflow.providers.docker.operators.docker import DockerOperator
from airflow.models import Variable
from airflow.operators.python import PythonOperator

default_args = {
    'owner': 'ecoop3345@gmail.com',
    'retries': 1,
    "retry_delay": timedelta(seconds=30),
}

def log_cfb_vars(**context):
    import logging
    cfb_config = Variable.get("CFB_CONFIG", default_var=None, deserialize_json=True)

    for key, val in cfb_config.items():
        logging.info(f"{key} variable value: {val}")

    # Push config to XCom for downstream tasks
    return cfb_config


with DAG(
    dag_id='cfb_weekly_processing',
    default_args={'owner': 'airflow'},
    start_date=datetime(2025, 10, 11),
    schedule='0 12 * * 1',  # every Monday at noon
    catchup=True,
) as dag:

    log_config = PythonOperator(
        task_id="log_get_season",
        python_callable=log_cfb_vars,
        provide_context=True,  # ensures XCom push
    )

    run_container = DockerOperator(
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
            "GET_FULL_SEASON": "{{ ti.xcom_pull(task_ids='log_get_season')['GET_FULL_SEASON'] }}",
            "GET_OFFSEASON": "{{ ti.xcom_pull(task_ids='log_get_season')['GET_OFFSEASON'] }}",
            "GET_ONE_OFFS": "{{ ti.xcom_pull(task_ids='log_get_season')['GET_ONE_OFFS'] }}",
            "GET_SEASON": "{{ ti.xcom_pull(task_ids='log_get_season')['GET_SEASON'] }}",
            "GET_WEEKLY": "{{ ti.xcom_pull(task_ids='log_get_season')['GET_WEEKLY'] }}",
            "INSERT_CAL": "{{ ti.xcom_pull(task_ids='log_get_season')['INSERT_CAL'] }}",
            "START_SEASON": "{{ ti.xcom_pull(task_ids='log_get_season')['START_SEASON'] }}",
            "END_SEASON": "{{ ti.xcom_pull(task_ids='log_get_season')['END_SEASON'] }}",
            "SEASON": "{{ ti.xcom_pull(task_ids='log_get_season')['SEASON'] }}",
            "PSCD": "{{ ti.xcom_pull(task_ids='log_get_season')['PSCD'] }}",
            "SEASON_TYPE": "{{ ti.xcom_pull(task_ids='log_get_season')['SEASON_TYPE'] }}",
            "WEEK": "{{ ti.xcom_pull(task_ids='log_get_season')['WEEK'] }}",
        },
    )

    log_config >> run_container