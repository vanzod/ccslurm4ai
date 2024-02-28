param region string
param monitorWorkspaceId string

resource moneoAggregateMetrics1 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: 'Moneo_Aggregated_Metrics_1'
  location: region
  properties: {
    enabled: true
    interval: 'PT1M'
    rules: [
      {
        record: 'average_dcgm_gpu_temp'
        expression: 'avg(dcgm_gpu_temp) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'max_dcgm_gpu_temp'
        expression: 'max(dcgm_gpu_temp) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'min_dcgm_gpu_temp'
        expression: 'min(dcgm_gpu_temp) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'average_dcgm_memory_temp'
        expression: 'avg(dcgm_memory_temp) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'max_dcgm_memory_temp'
        expression: 'max(dcgm_memory_temp) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'min_dcgm_memory_temp'
        expression: 'min(dcgm_memory_temp) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'average_dcgm_sm_clock'
        expression: 'avg(dcgm_sm_clock) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'max_dcgm_sm_clock'
        expression: 'max(dcgm_sm_clock) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'min_dcgm_sm_clock'
        expression: 'min(dcgm_sm_clock) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'average_dcgm_memory_clock'
        expression: 'avg(dcgm_memory_clock) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'max_dcgm_memory_clock'
        expression: 'max(dcgm_memory_clock) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'min_dcgm_memory_clock'
        expression: 'min(dcgm_memory_clock) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'average_dcgm_gpu_utilization'
        expression: 'avg(dcgm_gpu_utilization) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'max_dcgm_gpu_utilization'
        expression: 'max(dcgm_gpu_utilization) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'min_dcgm_gpu_utilization'
        expression: 'min(dcgm_gpu_utilization) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'average_dcgm_mem_copy_utilization'
        expression: 'avg(dcgm_mem_copy_utilization) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'max_dcgm_mem_copy_utilization'
        expression: 'max(dcgm_mem_copy_utilization) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'min_dcgm_mem_copy_utilization'
        expression: 'min(dcgm_mem_copy_utilization) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
    ]
    scopes: [
      monitorWorkspaceId
    ]
  }
}

resource moneoAggregateMetrics2 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: 'Moneo_Aggregated_Metrics_2'
  location: region
  properties: {
    enabled: true
    interval: 'PT1M'
    rules: [
      {
        record: 'average_dcgm_power_usage'
        expression: 'avg(dcgm_power_usage) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'max_dcgm_power_usage'
        expression: 'max(dcgm_power_usage) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'min_dcgm_power_usage'
        expression: 'min(dcgm_power_usage) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'average_dcgm_total_energy_consumption'
        expression: 'avg(dcgm_total_energy_consumption) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'max_dcgm_total_energy_consumption'
        expression: 'max(dcgm_total_energy_consumption) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'min_dcgm_total_energy_consumption'
        expression: 'min(dcgm_total_energy_consumption) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'average_ib_port_xmit_data'
        expression: 'avg(ib_port_xmit_data) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'max_ib_port_xmit_data'
        expression: 'max(ib_port_xmit_data) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'min_ib_port_xmit_data'
        expression: 'min(ib_port_xmit_data) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'average_ib_port_rcv_data'
        expression: 'avg(ib_port_rcv_data) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'max_ib_port_rcv_data'
        expression: 'max(ib_port_rcv_data) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
      {
        record: 'min_ib_port_rcv_data'
        expression: 'min(ib_port_rcv_data) by (instance, subscription, cluster, job_id)'
        enabled: true
      }
    ]
    scopes: [
      monitorWorkspaceId
    ]
  }
}
