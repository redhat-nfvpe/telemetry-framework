#!/bin/bash

SAF_PROJECT=sa-telemetry
oc new-project "${SAF_PROJECT}"
oc create -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorSource
metadata:
  name: redhat-service-assurance-operators
  namespace: openshift-marketplace
spec:
  type: appregistry
  endpoint: https://quay.io/cnr
  registryNamespace: redhat-service-assurance
  displayName: Service Assurance Operators
  publisher: Red Hat (CloudOps)

---

apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: amq7-cert-manager
  namespace: openshift-operators
spec:
  channel: alpha
  installPlanApproval: Automatic
  name: amq7-cert-manager
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: amq7-cert-manager.v1.0.0

---

apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: ${SAF_PROJECT}-og
  namespace: ${SAF_PROJECT}
spec:
  targetNamespaces:
  -  ${SAF_PROJECT}

---

apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: serviceassurance-operator
  namespace: ${SAF_PROJECT}
spec:
  channel: alpha
  installPlanApproval: Automatic
  name: serviceassurance-operator
  source: redhat-service-assurance-operators
  sourceNamespace: openshift-marketplace
  startingCSV: service-assurance-operator.v0.1.0
EOF
while ! oc get csv | grep service-assurance-operator | grep Succeeded; do echo "waiting for SAO..."; sleep 3; done
oc create -f - <<EOF
apiVersion: infra.watch/v1alpha1
kind: ServiceAssurance
metadata:
  name: saf-default
  namespace: ${SAF_PROJECT}
spec:
  metricsEnabled: true
  eventsEnabled: true
  elasticsearchSecretManifest: |
    apiVersion: v1
    metadata:
      name: elasticsearch
      namespace: "sa-telemetry"
    data:
      admin-ca: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUZOekNDQXgrZ0F3SUJBZ0lVSmgzY2d6SWRPUzdCbDBvbTZmQTZzMC9ZQ2xrd0RRWUpLb1pJaHZjTkFRRUwKQlFBd0t6RXBNQ2NHQTFVRUF3d2diM0JsYm5Ob2FXWjBMV05zZFhOMFpYSXRiRzluWjJsdVp5MXphV2R1WlhJdwpIaGNOTVRreE1USTNNVGt4TmpNMVdoY05NalF4TVRJMU1Ua3hOak0xV2pBck1Ta3dKd1lEVlFRRERDQnZjR1Z1CmMyaHBablF0WTJ4MWMzUmxjaTFzYjJkbmFXNW5MWE5wWjI1bGNqQ0NBaUl3RFFZSktvWklodmNOQVFFQkJRQUQKZ2dJUEFEQ0NBZ29DZ2dJQkFMVGRpbG84TkxNZjJ1YmVuRENLRVdtSE1naHcxaEI4QjZLRUFaR0pSaUh2NWt5eAphOE5ITHduWHJxaXFQZzRFdDAvUFNCc0FXS284RjRVMUZZZklUSnd0blNBV09mekU3eWVOQ3F6c0dQUGNFd1VUCk1IUXUrc3B3Z3J6ekZ5SjdtekJmRi9WVm9zK3UxZlM1YUN4MlhZaVRkMDBBSUxjSG1kTU9MZWxja1pxWFRRUnUKS1QzUHlCcXJLK0Y3Q09wbzNqNzZCV255ejlpRFZyazFZN2tKZnNpTjllUFhHQTc4VFptY0ozd3M1R05MUERQSwo4MnNad3V4aG4wNW9FWWVmUkwrK2NuaDd2cXRWYmlzZmQ3bzRTRHhTeXkrdzFlN1Erb25ueEdCM0NvYmlnYWZsClRHa2VMUUJhSThia1JkL1d4dXdFYUNMa1BvMnUyakVHWmRqbDJ5MmVwbmwrY2VEZm91cVZaS0ExbEtQbk1BQnEKajRld3hQS0xDOXhvOGx4SkllRXpLdjhsRG5zSnBmejEvR09nZ2F0NFZhSUNOU1hPVjMyTUdHTjVXaWlmaGdDQQpxbTlRaWRmRkk0SW02czB0a2xNU1lzWnlyay9rS0J6bGZFdWZPREZTbThhV0NvUnFBaEljVERvMHgrVUNXSzJiCnBwMFpiQmZOVlgzSC9WRk9oNExaenNYVjRrSFBlbmw1ZWJQTisvYWh5a05Cajl0b1dDczJHQXFrMjhEdXVHOFQKQXNiT25sUFRQWU1sMW45TmRvaFRTVnBCc2VLMUFBanhGVDBXZE5FV1E5dytPTmgxL1VpUklCWVNLNEhLQzlxcQozSDdhUDZjMU03bUZ1K0Zjc3R0c2FUTHJZdndZcExnMUFPT0t2NE1Ub1VUd3I5N2lCNnlYK1RsUWo3dkxBZ01CCkFBR2pVekJSTUIwR0ExVWREZ1FXQkJSRzZpVDZiVHJBL3JNb3IxRjJOK3lRVUd0UGtEQWZCZ05WSFNNRUdEQVcKZ0JSRzZpVDZiVHJBL3JNb3IxRjJOK3lRVUd0UGtEQVBCZ05WSFJNQkFmOEVCVEFEQVFIL01BMEdDU3FHU0liMwpEUUVCQ3dVQUE0SUNBUUJVNDFaM2c3OVJLRlVlS3J1a2xTR1RMcmRGNE5ZMHlPb0R0eDVqNVJYSTdZY0xSeGZjCkpzblZEWVAvckZEblBBeURoNmJBb2Q3a1l0eGdRNlAxOW9xa3hWZFBrRDNYbEpVdGtBdlgxaVZNTXM3MHBRTVAKVk9HL1NMVU9GUUs0YVB3dTRJUjQ2bSswTlF4UTV4NXh3UXVvU1UrZzJ5akltNkNpSkVlUGZWbnk0R1pqTTZmOQpIUGpCK3JNemlPRVpXYnc3b2Zsb3dPSnIvMytlSXI3S3dQTnl1cmJaQXpMQUNodnlSalUrdjZoUTNPZHJTRFRvClZPOU0rN05SOG44TkxyeEp1WWwrV0RYenoyM1JiOXYzU0Zzc0dUT0Yzd2NnVzBUaXEzckxDT2tpazFKSXFmci8KNXF4a3N1TVhucytjMlFtUDRhdmRsdmcxck9ia2l3RU1wNStxSTM4bklvcVBJS2I0RktVbkozNE9kazNZV2NhVApSUzEwckxnWDRHMzV4RWpIbHJBeTVGdXpSdWV2cmVtL05oT3VLVkplRGtCd3RTVjNHRkhjUDFPa2IxcElSd3N5Ckg2VFJaZUlXUDMrN1VDRjBsL0F5RjgvYXFnK0MwZVk2QlFhOUpOdWUvZHRYazBmQUcvRlFFQ29NTU45WkU1b1cKYnRBaSthc2p0S2haSlZGeFpTMTlYdDdxNlpDR1lmdnlDWVNWNkttb1MweVlXek03UkQwSW9GeGlzUm9IYmhnWQpmTFJSdEM5Y1B3bkVIenFJeE5XOVdUTi9MbGhDMldSMzhMNkhqQllMeGhNU3FCa0tzUHpJcXVRK1BNOVNEQzdGCld5VytTVGxGbnFUdG9zU2JQM3dlOVRtaEJ3MnI0Q0RTQVVqMUVSYXJKY1dCMExuTDZSVXZEZzlXNVE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
      admin-cert: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUdvRENDQklpZ0F3SUJBZ0lCQkRBTkJna3Foa2lHOXcwQkFRMEZBREFyTVNrd0p3WURWUVFERENCdmNHVnUKYzJocFpuUXRZMngxYzNSbGNpMXNiMmRuYVc1bkxYTnBaMjVsY2pBZUZ3MHhPVEV4TWpjeE9URTJNemhhRncweQpNVEV4TWpZeE9URTJNemhhTUQweEVEQU9CZ05WQkFvTUIweHZaMmRwYm1jeEVqQVFCZ05WQkFzTUNVOXdaVzVUCmFHbG1kREVWTUJNR0ExVUVBd3dNYzNsemRHVnRMbUZrYldsdU1JSUNJakFOQmdrcWhraUc5dzBCQVFFRkFBT0MKQWc4QU1JSUNDZ0tDQWdFQXhzS3ZnQXk2anRkYTFxVWFNYi9sR1RSdWtOY2J3TUlURlJyUzZ6b2FUalIvUk5BNApnTUJWMHBhTEJ2dW54VUZFd2p1TnFISHNLQWpaUFhacWxuMllZRkpMNHZjQVNkSWh5OWVockhKSE9DT3pQK2doCkd0SmY4RVVpV1ZIOXczdWc3UThwQWkzVWJza1RTYkRmZnp3V3ZPM1ltZzM0U2RrZmRmaytIc3pvOTBJMUxEQ3kKdjBha1pNUDFBYm9Oc2JJZ1FldkVQc1JYRVpmbWxyL29COENWc0lER3F6dWowK1ZSNmtMOFo0TDB0Y0JoSHVxNApQSkVIZXV5eXRlN0NFSTloUHVXRG1SS2tVazFtaFYweUxPSHR0S21Yc0tGd0htSTBNOEt0Sk5JN3llYVB4azh5Ck9vL2tDOFZBQVdtUzFXNzlLb2c2ajZtOWk3K3RxbXU5c2NnaVpLZEdyMU1hcXExYlovek9qSytOVm1NakVDU3IKL3hBUWZlRjFrcmdidkthUTBCSlNvQkl0YzZVNEU4RGQ5WENWUjdReWxCdDI4MGdlbVR6YlEvMkZTYWp2Rm5jMAo1UitvbGNOTEpjVWpxeHZCZG9zRURvYWkzZExSUmZmOEFKRUlmRm42eXpMdW5IQi93QTVNUlI0aHBncnZzUUhnCk5YQm40R3FCQjFDTWU0cXR4M1JKM1VvMk9sdENHdW5WVEF3MEFjMzVPREc1dEkzaERqclR6RGVYaVlqT09TUlIKd3JvWk1IWk5RTmFtWnhDZE5wcERDRndDUExPUlF6WmZKcldvMmY5NHQ0OEx5SFZRMFVtdGJ4eEczSUoxQTVKZApTaFBnOVNjNHRMMTlnVXg5N2R0ZkppWVQ0U1pNeUFWZXVLelNBd2x4SjQwVUd6UlIyTFVqU2ZpZDdORUNBd0VBCkFhT0NBYnN3Z2dHM01BNEdBMVVkRHdFQi93UUVBd0lGb0RBSkJnTlZIUk1FQWpBQU1CMEdBMVVkSlFRV01CUUcKQ0NzR0FRVUZCd01CQmdnckJnRUZCUWNEQWpBZEJnTlZIUTRFRmdRVU52THRYT2NiUlV4TEFRcnRSMkszNDRYbQpGemt3SHdZRFZSMGpCQmd3Rm9BVVJ1b2srbTA2d1A2ektLOVJkamZza0ZCclQ1QXdnZ0U1QmdOVkhSRUVnZ0V3Ck1JSUJMSWNFZndBQUFZSUpiRzlqWVd4b2IzTjBnZzFsYkdGemRHbGpjMlZoY21Ob2dodGxiR0Z6ZEdsamMyVmgKY21Ob0xtTnNkWE4wWlhJdWJHOWpZV3lDSG1Wc1lYTjBhV056WldGeVkyZ3VjMkV0ZEdWc1pXMWxkSEo1TG5OMgpZNElzWld4aGMzUnBZM05sWVhKamFDNXpZUzEwWld4bGJXVjBjbmt1YzNaakxtTnNkWE4wWlhJdWJHOWpZV3lDCkZXVnNZWE4wYVdOelpXRnlZMmd0WTJ4MWMzUmxjb0lqWld4aGMzUnBZM05sWVhKamFDMWpiSFZ6ZEdWeUxtTnMKZFhOMFpYSXViRzlqWVd5Q0ptVnNZWE4wYVdOelpXRnlZMmd0WTJ4MWMzUmxjaTV6WVMxMFpXeGxiV1YwY25rdQpjM1pqZ2pSbGJHRnpkR2xqYzJWaGNtTm9MV05zZFhOMFpYSXVjMkV0ZEdWc1pXMWxkSEo1TG5OMll5NWpiSFZ6CmRHVnlMbXh2WTJGc2lBVXFBd1FGQlRBTkJna3Foa2lHOXcwQkFRMEZBQU9DQWdFQUx1UlFnd2kvZVVDK1FrdWQKZ2t4OEdOVTZnZ0ZVdXdibjg0VUxOSWtacXYrbUdBZTZ1ZktlYmFiQm9iTXF1WGFBVnFNOWxRQ3J0aVprWVpRMApDU2NXeTFGSGpuREh3dkxNTWlmU3RQVlNrZ2lxR285cW80QkoxSDRNQVpKaUNGZFdJcnJpZ0tmWkpUcE8rbnBDCjdXUVZqME4wQkNKdDg0di9vS2ZrMkM2L3Y5Qk9JbjZQZ0ZoNG5MN052dnZ2NGt3VlRWWlFvR1JIb0MzaUNhRDQKWDVoa2l1SkkzMDBYQlhYNnBiZW5oYlVBUkJYZE5PUVpKT09yNzB1TzBpRzE1VC9jSTJ0TlNIc0ZzY1hUaWhJbgoxVld3N2pWaU9HbUhjWUJUb1ZVdHNEOFBodG9YVVJoTmVpeituT0t5Tnd3MlhBRUFZYXVSMWt5d3BTME1yYlVDCjJMbk9UL3QrVGppcnJCRjRtaDlSWEVNVDdaSHk1RklOeDJwNHJ6aUhicENScytFL1NldmNVc0RrL2NqTzIxaGIKR1NpOFlHOHNiT04zWFF5WS9sMUZEWG1aYVZ6NzUzbnVrMFZQWjRNTTFUQUpGcnhBV1Z2ZkpsUkh4bHNZVWtCZQpIdW1YWXNoOXNQQlJCQ2NwWTV3VnJ3eXFQcWs4RE1MV0dCK0RMVWI0TWo5QzU4WkFNNWZDWjRyb3Q2bXpmbnZ0CjBBcFZ6UDZSdXloZEFsWm9jS0UyYm5iNWxDM3I3cXdiUEN4TE8rY2Z1WDhhZ3R6TmZucFVTczlwa3dZY2ZIQ0kKdUhWOXc3V2h4aWNsOEVBRUZzNnhmUE9qdDNyS1UxZ0EvRUJ6bGVzMHpEaGJubTJ1a2NqV3lGcjFNMHhhbFpaSAoxL1N5VVYrRnNNMXlTMTNmSUE2eVhvYzJNZmM9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
      admin-key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUpRZ0lCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQ1N3d2dna29BZ0VBQW9JQ0FRREd3cStBRExxTzExclcKcFJveHYrVVpORzZRMXh2QXdoTVZHdExyT2hwT05IOUUwRGlBd0ZYU2xvc0crNmZGUVVUQ080Mm9jZXdvQ05rOQpkbXFXZlpoZ1Vrdmk5d0JKMGlITDE2R3Nja2M0STdNLzZDRWEwbC93UlNKWlVmM0RlNkR0RHlrQ0xkUnV5Uk5KCnNOOS9QQmE4N2RpYURmaEoyUjkxK1Q0ZXpPajNRalVzTUxLL1JxUmt3L1VCdWcyeHNpQkI2OFEreEZjUmwrYVcKditnSHdKV3dnTWFyTzZQVDVWSHFRdnhuZ3ZTMXdHRWU2cmc4a1FkNjdMSzE3c0lRajJFKzVZT1pFcVJTVFdhRgpYVElzNGUyMHFaZXdvWEFlWWpRendxMGswanZKNW8vR1R6STZqK1FMeFVBQmFaTFZidjBxaURxUHFiMkx2NjJxCmE3Mnh5Q0prcDBhdlV4cXFyVnRuL002TXI0MVdZeU1RSkt2L0VCQjk0WFdTdUJ1OHBwRFFFbEtnRWkxenBUZ1QKd04zMWNKVkh0REtVRzNielNCNlpQTnREL1lWSnFPOFdkelRsSDZpVncwc2x4U09yRzhGMml3UU9ocUxkMHRGRgo5L3dBa1FoOFdmckxNdTZjY0gvQURreEZIaUdtQ3UreEFlQTFjR2ZnYW9FSFVJeDdpcTNIZEVuZFNqWTZXMElhCjZkVk1ERFFCemZrNE1ibTBqZUVPT3RQTU41ZUppTTQ1SkZIQ3Voa3dkazFBMXFabkVKMDJta01JWEFJOHM1RkQKTmw4bXRhalovM2kzand2SWRWRFJTYTF2SEViY2duVURrbDFLRStEMUp6aTB2WDJCVEgzdDIxOG1KaFBoSmt6SQpCVjY0ck5JRENYRW5qUlFiTkZIWXRTTkorSjNzMFFJREFRQUJBb0lDQVFER290cHh4a2JMYWozR05jb3YzZTgvCmVUN21VWlBTMkNIcC9aeThxSnlSZTdXVk4rTEFDWGU3dGVmTFdzVVlSVnBLSXVvM1pXTDF2NkliNHJRekllR2UKb2FCbGV5UTJvbUpVTFhQTnU0ZWhlMHd3bWZRN3NmTmZWRGczdTlFNEE5MllESWFYUHVZR3NiMHM4QzdzSVVrNApGeHRaR28wQWdKVUllY2F6VVdXaGRmRmQ4RzB5NjQ1dmhjYmRxdXIwbzJmSmVhM3ViSm4zWXk5M2lPS0NuTno4ClFEWkwrcGFIdGE1ZnlBSW9FS0F1NDh3cjhiZWVEL0xCenJ2clJtbDcwMDhFWkt0WDEyR1JQdmt1WHkwOTNheUoKMk5OWUduN0tYcXA4OEJuSnFyRkYzYjNpR2xQQVl2MHRKandKTFZFcExIcW1mdTdIbElOeG5tWVk0d1A1SUdIOQpJcS9ZWmRQN2hLMFI1OEphUGEyK01VUWxpalRQam8rNURibmZJbzNHbDdmN1VPK3BYU2oySmNvWkFWNEIydVlxCkRNQlVnVEtDdS9WMWYzZ3phREIyb3NSbmNUUDNYYmkwcVAvbXJ1Rmd6bSsvU01pSVZWR1FPRWZsbHk0QVltZnEKQ1Jkbm1udWFFZ2tWUTdCMzFjSUI2emdJd2Q2UlR1cWVWaktWdllOTlQxdTZlUFNtSk16VXB5YnBzWWMzaUI4NgprVmRMaFdSWmtYdjJ0RFE3VURkeEFNV2JtMHJObWJKa2h0UUIzMzFRc1VmOHNmTmJZSE1Na200QXJLUXE0a2xhCnVpOTd5K2tGc25BODlhZ2xTQlQ3ZDF5WWxiT1VlZ2hreHdscmxRaGhUdDlhZ1lYNk5XQ2RkN0pNRlZyb0JnMlMKK1VuUnpqNnZ4U2VyWllrRXVPL1Q0UUtDQVFFQTRwN2hxRkNtNDh6S3QwTEtZRjNkM2srczFINjhjRWxIaERsNQpuNkJMcmFRVFVvY3FtVVNhaGNrOHFtV1E1Rmhzd0RibUEzcGViVkk4U1ZXcFZaeTgyNjZKSVpxYXcrU1VpUjI5Cjl5REJ1dVVObkpmZnJLajNBMWgyMXFEU0dVY2J5RmRIZ01yaVgyZ2pDZDZtNnhqZmFCMDVpNEZXUmpzL0cyVHoKLytxbXJ2MkNYdTlPYThYcmpVOXFIQlVBeWJsalRSWkEvNURTSWxTYVBvZ01JL0Qxa21rOUxyZFVQZllUVld5eQordHN3Zm81ZDhtTEx1aityUFNVKzVSR2ljY291R2VOQUk1SEtYZWpVTVp0Z3JiYktmR21SRWdPWEpDbHFFUm4rCklUU294TnJTMGc1NDBNT3NqUUZ3RjRZeXdncGYzUGE0bUh6c0ZXOVQ5NHh5dDYydlV3S0NBUUVBNEljdGZCWlcKWGMwd2Q3ZFhIbWZkZFphckJRY3E2TE5UcEZ4SlE1VkQzR0d6L1lJZnRyQXM5Y2dXUE45aGF0ZWVMNUtjYTdLbApYdWpQOEk5eFVROGNBR1dBNWcxenlJenVQWUZkUFpSSVorVDBpN1R4R25vVlRPUktEWHg4RzNxcEUvWnY5U3IrCnBpdkEzVUhEMHEvaEViblhvMzZZOGJmaDBGOVo0NCsvTmFWSmlWMlFQVFFqODBUMHorKzVuR0huODhzT21TRWEKUG0vZlZPYW93NDlQRzJ3b3M3RzVPMUQrRXMzU092cmwxdGpxUUxBUHh2SHoyRkM4ODRJRThZV1E5ZFhMZlRmeQpLaFQ0dVg0c1l3UUFsdm9IMVdMU0x2eVBEMDl6bTF5OVRDRWxXZ3pPL3pmdDlmSU9NcXhKb0dacTlOVHlBUUNoCmxPMkY2SkVrR3YzQ3l3S0NBUUJTMFJsS04xOGw5SnRJYWFJbm9XWUpiamlNMTF2cDlQMnJ0bzFaNW15Qm9tcGwKU0h3cTBzVmRpdk1lbWt0ZkIybUd2UWxGMEJ4ZCt5V0k3ME1ZeEZUSU8zcGx5Mmd2bW9NbHNMYlJieWtkTWNQTgpyRHJUa0ZQazV4bFd5aUs5bGh6ekUrSlBrTlUxWklzWmVrS3B1OGM0OXlVbWREZWhKdG1qR3p1SUZLcWhYSWVlClJmbjByTG11UkkxVWdlQnQxOUFRUmNldkhhK05XRG1lREgzVFRLV1J3ZC9ZQ0t0Q2tZRHpRT3dQZkxhMktUVHYKOVdiYVE1WkNuQy9sNnBIZzM3QUZTZVVRbXFESHZPUisxSGQ2UkVpdk9xMEhWa1NQdElyTWdTRTc1VkNmMEJBbgpMNTY3UENiOHlMKzcrUkRubEg3Lzh6SDJtQUIydk42RW90RHhpd2w5QW9JQkFCZjR0clY1MlF5NHZJVDdrUlNRCitFYjJxQm1vVXo5MjdlWXRhREVML2F2SXpxT3hRZHVLWWJKNEEwL0tkYWNua0I3Nkl6TW9acG1FZDdieVNhSGkKNEJWMndOVk8rRjZnRlV1QnhVZXV6akF4ZEo1NTJnZitvc21MMGhBd2l6dVAwLzlxbnpkb3VMbGJFSU5PNHk1YQpVc2hHdEN3amR3YlBvQTlVTHMrcDZEczlBMlhrRkdORWJ0WXBOWTRCeFNwYUZaNmt2bEZCQklGSUJtc1ZHVTJQCnZsMXFKY3BSbmpva0FveFZaeTJlM2UwYlNaOVFiTTdMeEVJREZMbFcxMXBGN1YwaHoxRDJLU2V2QjRNZVluVEwKMTVoRzU1RXp0TWNKZGVpbmplczNjb3B2TzRLcXZXcm9PTUs2YmlPZzIxZUJ0OGVkK0p4OHljT1J2R3RCRzc2NQoreE1DZ2dFQVFGQ2IrM0loRlpabUM4aWdhQjFlTU9wNERlbW9aVzlnakhCdUovanloVWxaRVljS0EzK0hNbFg4CmhQQjhWM2NUYk5kMjVqZEl3VFJmRDk4SE4vSnRlVk1ZRzYzR28yZGpHTGVNaWg4SzVzMmVVRmVWRWNydkcwaWUKblhjWkd1STlBa05pOTVPRS81bXUzSzFxYThDN1dMZC9xVDY0dnlaVWtwSU85TEJ0ajJCTTdlUENWTUdFblBsUQpWdm1MNjd1OU1rbzYvK2hkNGRVTkY3QTRzcmxJT3NDS3o3ZHNUYWp2MTNGTzArMGhBTTZXYmxSdDIxV1NhUG9lCnlhMEZpMjEyOHd1YXQxbzJJbWJsYUJJNEZ5c0FlVnFQaEdyeWRlMmtjeEFWU3orTjZoTXM5S1VhOU02dm5QSzQKVTRkTmZTSVhBQjFWTmhTNEVQR3VZVW1IQ01wVDVBPT0KLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLQo=
      elasticsearch.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUdvVENDQkltZ0F3SUJBZ0lCQmpBTkJna3Foa2lHOXcwQkFRMEZBREFyTVNrd0p3WURWUVFERENCdmNHVnUKYzJocFpuUXRZMngxYzNSbGNpMXNiMmRuYVc1bkxYTnBaMjVsY2pBZUZ3MHhPVEV4TWpjeE9URTJNemxhRncweQpNVEV4TWpZeE9URTJNemxhTUQ0eEVEQU9CZ05WQkFvTUIweHZaMmRwYm1jeEVqQVFCZ05WQkFzTUNVOXdaVzVUCmFHbG1kREVXTUJRR0ExVUVBd3dOWld4aGMzUnBZM05sWVhKamFEQ0NBaUl3RFFZSktvWklodmNOQVFFQkJRQUQKZ2dJUEFEQ0NBZ29DZ2dJQkFQb3poSWZaN0VGUVU5VzhpNUFhbnlCNWRLRUxZc0pYMXZiVUkwSjdTdUVTZnZCego3NXFEVDZPTEh6OGpNbGtiMThDTzV1MGZjQmFOdEg3Y08vM1lscm9VZzVyaEZvUEtwUXh6U1JsOE52SXhsOE1rCklEb1FBSVVTTStaUXEwRjNoY1I5T1lwWVkvWU90YUd5UmlNRndPVmpSeW1uQW5XWEwxVG1VcVJvZjVleEs3NHEKdytXOUtQd1VGWEtNanBtOHNQOW5RUlpUb1FXSzNVZUVXTHU2cHI2dlJCcEx0RUtQL1ZKRzRjQkU2THZkVS91cgpDMFFSc0xhTGp4c0lIMUNNcVF2RW5ub2JCRTI5T1hDdDB5ZDdTNGJ0aEZEQllrRjU3UG1SWjZDM0kyT0VNeDBECnlxcCsrUlV1aCs0YlZsVkp3LzNUK2lUOGx6WlpOeUN2ekpJVjdHWWFpTXRDS1drWE1EVGhRdGUzeTNCb0xxT04KWGxPbHo0dWVNb0prRW4rUWV2TmpPT1pvS1RVaStXK3E4Ni9oc050eEg0ZDJJQmdUTy9QWEFQbDE2ME0zUHRvdAorc2VPdkVqNVEzU29ONjdqcCtRa3kzVU1MMEV5VFJHeEVYMjE0LzFQUnJxUnNQZnlLbEI2eGp3dlliYTloN2FnCkMyaGlxSjNGOXZaTVlSdkZ1dG5qVnYwMVpwdk1yZWRiOUpBQ3NpKzMwcUVKNVNDUEd2L0dIWFJXZzBZZ3E2OGIKM0Zjd3RRUTUyNDZlVUlLRm9hc3EvT043dnBrZ3RvTEtMaHk5STNYbU1MSTNWdzE3Nko0ZzJMd1F0aWJxaEdWdQpHTVU5SGJROHZxaDZoZ3B2blNieGRGSXhjOUZmeEpJWnVhRnhKWWFqMm1PSWhWLy9wczJ3NFJ6b2JZNW5BZ01CCkFBR2pnZ0c3TUlJQnR6QU9CZ05WSFE4QkFmOEVCQU1DQmFBd0NRWURWUjBUQkFJd0FEQWRCZ05WSFNVRUZqQVUKQmdnckJnRUZCUWNEQVFZSUt3WUJCUVVIQXdJd0hRWURWUjBPQkJZRUZENXovSzlzTzBMUGdjazdRSTk0V1FndAo3NmJETUI4R0ExVWRJd1FZTUJhQUZFYnFKUHB0T3NEK3N5aXZVWFkzN0pCUWEwK1FNSUlCT1FZRFZSMFJCSUlCCk1EQ0NBU3lIQkg4QUFBR0NDV3h2WTJGc2FHOXpkSUlOWld4aGMzUnBZM05sWVhKamFJSWJaV3hoYzNScFkzTmwKWVhKamFDNWpiSFZ6ZEdWeUxteHZZMkZzZ2g1bGJHRnpkR2xqYzJWaGNtTm9Mbk5oTFhSbGJHVnRaWFJ5ZVM1egpkbU9DTEdWc1lYTjBhV056WldGeVkyZ3VjMkV0ZEdWc1pXMWxkSEo1TG5OMll5NWpiSFZ6ZEdWeUxteHZZMkZzCmdoVmxiR0Z6ZEdsamMyVmhjbU5vTFdOc2RYTjBaWEtDSTJWc1lYTjBhV056WldGeVkyZ3RZMngxYzNSbGNpNWoKYkhWemRHVnlMbXh2WTJGc2dpWmxiR0Z6ZEdsamMyVmhjbU5vTFdOc2RYTjBaWEl1YzJFdGRHVnNaVzFsZEhKNQpMbk4yWTRJMFpXeGhjM1JwWTNObFlYSmphQzFqYkhWemRHVnlMbk5oTFhSbGJHVnRaWFJ5ZVM1emRtTXVZMngxCmMzUmxjaTVzYjJOaGJJZ0ZLZ01FQlFVd0RRWUpLb1pJaHZjTkFRRU5CUUFEZ2dJQkFEOEQ3eUk1bGRtSnpLbVcKQzZjZEFJT0M3U0ZQTXVweDVxcEpoQ0o3bEswam1nRlAvaW11TjBRd3c2NEFMWGlzNnJaQm9OR2tTUk53YUJKcApSZFVaWC9peWxLbUs1UW1OakxNMWNFOWdJajRzai9UUjBOY2lPSmZTVEgrd3JHc0k2Z2M2OTg1d0NmeUQ1MVBCCitWd1lyQUlhVmx0UFFWbzBRR2thRWZDV2ZrQm1lZlhYbUFqZUJSb0MwdjhGajlHVEdZVjJIR1N0TmJ1YmJvUzcKUFZCK3VQcjB6c29wdW9UWFRQbnpNS2VXOGxSQzJQeWRzRW9FUGtiQW1Mays3VWwyQ3FTZTNRSmJVdllua2ZKdApiVk41Z1BoVDdkV3FPa0NLZThWQWxZRWpyZTRMSStNSVFMMnVCR3Z6NFVWOUx3N1RlbTltZml5SVI4THJsNXRvCnZpZ1k4UWU3SFNHUE4ranowYVRycHRZU20vWjlHN2JtWWJWUG9rSURPckJkM05nb1hqaGFZT0JtUklUbSt6aEgKWDRvamo1d0xuTllDVGRtZkFKdnlDN2ZrRE5xOHFxNG5LZXZGTWNQV044VDJ6TDJuZDFEOTNrMlh0SWxBL1Z2MwpXUDdXYStwSDVDSXY2bGN6NnFpRkhUeVJFbDBSUW1HZ0kvWnlkRFBXa0VieTFWbXZ4R0hITDQvTDhUdVdLYjh6CmVQSXBMc0g5WTIxU1ltVWxZb2xLdGJwNzAzWnNZaW9QNmV0aWlDUyt2ZGpNMXdtQUNYcDZnVDF1cXhQSEdlVWcKQ205OGNHcTAxOHVKZ3NqT0MwN2cvR3Bqd2R4cEpJTXpPcU5nMXE1Z2RqUk1JdExLTm5FVDM3NFlldlB2L1Qrdgp4c1ZQemRUL0ZyK2ladC8vQ3pJT0JNVzU3ZUxsCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
      elasticsearch.key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUpRd0lCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQ1Mwd2dna3BBZ0VBQW9JQ0FRRDZNNFNIMmV4QlVGUFYKdkl1UUdwOGdlWFNoQzJMQ1Y5YjIxQ05DZTByaEVuN3djKythZzAraml4OC9JekpaRzlmQWp1YnRIM0FXamJSKwozRHY5MkphNkZJT2E0UmFEeXFVTWMwa1pmRGJ5TVpmREpDQTZFQUNGRWpQbVVLdEJkNFhFZlRtS1dHUDJEcldoCnNrWWpCY0RsWTBjcHB3SjFseTlVNWxLa2FIK1hzU3UrS3NQbHZTajhGQlZ5akk2WnZMRC9aMEVXVTZFRml0MUgKaEZpN3VxYStyMFFhUzdSQ2ovMVNSdUhBUk9pNzNWUDdxd3RFRWJDMmk0OGJDQjlRaktrTHhKNTZHd1JOdlRsdwpyZE1uZTB1RzdZUlF3V0pCZWV6NWtXZWd0eU5qaERNZEE4cXFmdmtWTG9mdUcxWlZTY1A5MC9vay9KYzJXVGNnCnI4eVNGZXhtR29qTFFpbHBGekEwNFVMWHQ4dHdhQzZqalY1VHBjK0xuaktDWkJKL2tIcnpZemptYUNrMUl2bHYKcXZPdjRiRGJjUitIZGlBWUV6dnoxd0Q1ZGV0RE56N2FMZnJIanJ4SStVTjBxRGV1NDZma0pNdDFEQzlCTWswUgpzUkY5dGVQOVQwYTZrYkQzOGlwUWVzWThMMkcydlllMm9BdG9ZcWlkeGZiMlRHRWJ4YnJaNDFiOU5XYWJ6SzNuClcvU1FBckl2dDlLaENlVWdqeHIveGgxMFZvTkdJS3V2Rzl4WE1MVUVPZHVPbmxDQ2hhR3JLdnpqZTc2WklMYUMKeWk0Y3ZTTjE1akN5TjFjTmUraWVJTmk4RUxZbTZvUmxiaGpGUFIyMFBMNm9lb1lLYjUwbThYUlNNWFBSWDhTUwpHYm1oY1NXR285cGppSVZmLzZiTnNPRWM2RzJPWndJREFRQUJBb0lDQUhYL2JmV1Q5VFFvYWlGWE5vclR3MUJSCmQ0dXNEdnVRNmJTbS82b084NVdLWDR1UFllVUJJTUlFanN2OEVYYXRCdWV0ZllNL1hHR0dteVZwUUhITGYrcHEKV2xiazZQVm0wTWc2WnJNNlBiK2pXK3VRVWhLUUVXNncwd0UvOGtTQjFmaUJCbTRVbWJBbDU4dEdoSVZuNVQxSgp3UG9INWNVSGRDOGFJTWVnOE92ZGhyKzg4MzZaNDRaZkFtNXZrNkUxdUZQN29scWhQa09hNWhrZ2RhaXpzb2dqCnFINnVUV2xHOXpXaWNEMTVRam0zZkRBb3pydGZqSFBMQmNhOTRlYmZMNnA1SkRSNklXRjRhR3FYMEFuQ3dDLzIKUEh6SmQwbGg4ejBRTWtzOWs5Y1BOZnZ0R2R1bTNsbjdBK2hyeEIrZEZtM1RWeG15ZHE0UERVekJIRDJaVVU4MwpaQm9NNWxhbGhaQm1MajJEdmlZbGZ2ZldjdWh0ZkdmRFZNWnFnU3U0cEFKOWRkM2s3SVQwYmw3Q2VEaEFhRFQ3CkR6RnhWb2tJMkFNUDJBaGRDSGswNnlWQ21kYzd2SXlFQStsQTBZVit2RG9NZC92V2Y5cFdVYUxLbDFTWG1IbzkKaVAxY3ZsRmlDbXZCak9HamkzMXk4QUpzVHJ4T1J3dFlhMTRNdEZRbTZHZS9uSzYvK1d0RXUxZXY4QXBGUUVLOAo3aGhURFBOYXE4cDFKK2lXRlBzbUI4a1hvWFdzSXNWdWE5cUJXQzVzV0x4c1pwWVFMU0JsNG93d1pwVGdvMW5RCjlpbWRsSzIwODFTMEtkRmdJZHpWSDAxTk05d0lNQ0luME1vd0pqR0xEazZ5SUNGZGhieHY3KzJyR3Bmd2lqYlcKanFOZlJPYnlUc2pPZUtmWStsVEJBb0lCQVFEK0F6OFRvcCtQSG55RUxLdkpFTjlWcU9XUUhGNXBSQklmRFB0NApjMkQyUmVTWFRDSmd2bTRzMVNxLzdtV2V4cXpnU1NWbUROWDZBTXpXTUc1Nm5Yd0gzeE9JT3BBTjRpU0xBc1pJCnlTMFVLTzlGUlQ2RUFkWFQ3d28wUHZkdkcrWE9teDc5Tmhqc21LQ3ZLbUc0V0V2ZFFSMXUya3dmZUU3cGdSNmcKdXRSejdtdFYzZzBJcWNyYUZwMFRKTThjQmhldm1BNG1raUVnd2lnT2xQd1YvOURCL0hMelZHY1JLVmYvQUs4NworVDlIN0pmenZzVm4yMUM3MWFsMUs0VTVoODlpdTNXRzNmc1AzOVVaUitNcEEzRUlQdlVUZk55LzBKdkpPb3BKCks3OEltbzNZTTZBOHZCdWtjNVlUeTlLc2lpTzVENGJpZlVnVnFYK1l1aldBQkRrWkFvSUJBUUQ4S0tNeS92U2kKdEZlZjJ5S3NOSklyS1kvVG4zWTE2V3d1SzhZMHJZdkpKOUFSZG9jdG1MOHplTk05ZFQrNGZjemVxT1AvSE5BegpaVU1aWHpPVENQS0NJYU5aVTNlUWwwaGZhQmlWV0dQS3h2RmJCS3QrMWsvckk2MVdYNUZ6VE4wdEZwaHpqUUpXCkF3TDBEbE9GUmduSWlzMlJxSkwrZXpQdU1pTGdWekJWVGtnZStuV05rNnllWW5HRVdYV0VyeVJZeTZSbmtpaHEKclRlRjBVODRTTDJyUWhPMThiOExLcWRJbC9EdTlUc3ZtY1RpdkJlNkU5anpjcXd2RFhzeHBCeU9JRTFTc2NPbwpPVmRMNUxBalo5eEtaa2pLdHBublFGcWRDWldlNlpIK1NSNVlwQ2hJNEhHNzRHUzVTN1VxVE01SmQ2ZXdxZ3pyCjFKaEw0OHVaQjNOL0FvSUJBUUQ2R2hneExSNE52T2E4L1g3bktrVzhBZUNHVkdoaEhUVDZmYjNjaXo0ZFBoUWwKSkVGMUlBczYrV2h1TWp5OGFNSXUwOWFPOUhSN0ErNnJ0bVFSTnA2NDRWeEo5ZCtBeS9sUEpodzE3bDhFU29uTQptckZES010eE1Sdks5WFNMWWR5VDRRaFNLTUhCczBZRE1xZWs2c3RIdnFWTVVJUkRPQ0g2cDdlUWFtUmxBWXVOCnNHVUU4cWxZc290V0hoZ09iN0ZDbzJUTGRYWkkydUsxK050OGpiVHVTN0tqQTZlM3JnMkdkeFlTNXdiM3VteWoKQW1NOEx5VCt6UkZjM00wQUtFaDUzam1KNFdjaDZqSFlBb0FZRWR0cFV4UGJiRVd1VjZnTUtpZWVoQVJFWkdqbApSMit1WFVpYVUzU2hhVDYxeEE0SVdORm1rQlE1di9weVZtWDI5akdCQW9JQkFRQzJEVkRtZkpSNjgrRmZsSUxQCitaU2VmUDlPTm83T0ZaejVLTG1OUnM3cGlFajhrcXErRE0zZWg1bGJnYzlqajgvZDRlbmFRaDgvUEJqWnRKWXoKemYzb1hnamxjUkdkM3R0dHBtWTVUUHVmWjByUi8ra2hSZkdsUHJqaTUxVEgvZktobnZLcVdtQVpZVXM4a1N0VAp5V0UrM0pmV1ZmTHFzR0NwMUtEQmY3RnhwWGNFaHFkZ2RBSG95QUpWSDVGdEhsWUxsZHM0dTVsYWkzek9ySE9aCm0wcjAzbHdFdkdqRjB5RzdrNWRycnJud2dBQmFBcHJPeVkyVkZuR2g5d1crclZIQWV5bllUbWVJaVAyeDJZWWgKeWRhT0VKTDFhQ2h0Z1ZUcWxBVG1HcFJCRnVGRjloN3ZucnYrZk4rN3VDRXdUUXVTbDBVR2szK0l0SkRRR2NMZwoxVFJaQW9JQkFBUGVJYjg1RmtLY3NUNmFGQzQybnoxdHJJcC9RMTI2bWdTbHdVZGQyTkRCTXJxN1N2dWZreGFVCnFPY1J4WUlHQ2pHNmIyRDJndS9uRnpZM0g3aWZsUkVXWDd2VVk5SkpJbFhLbG9LaGpKeXpjdml2aXR2OEJ6dXcKSXUydkJ2bURrcjdaTVp2MFB2Q2JCODVDQ0RQUkd2ZUtWZXRGZkpoZ2x4MkhweU1aVVdhWmhPbjU5TnBhNlBITwpCSFRqWTk5eEd4aDA0MDRJZEY1cWtFWnpRQ1ZOMnR2NzJSeGhORWNPeCs1TWlZNEFyYy9BRVdBVnEwWDZNcUhBClpxK0UwQ1orV0JUb0hzVnJMMVk1dlUxaEF0d0U0NS9kQnBDTDVKZk8rV0FIK3ZpR2dTaUNaZW40Qkc1TE0yb2kKUEJ2OWVpdWZzR2NNWUJlOCtXa3UydlRMbXVzQ2Y0RT0KLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLQo=
      logging-es.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUYrakNDQStLZ0F3SUJBZ0lCQnpBTkJna3Foa2lHOXcwQkFRMEZBREFyTVNrd0p3WURWUVFERENCdmNHVnUKYzJocFpuUXRZMngxYzNSbGNpMXNiMmRuYVc1bkxYTnBaMjVsY2pBZUZ3MHhPVEV4TWpjeE9URTJOREJhRncweQpNVEV4TWpZeE9URTJOREJhTURzeEVEQU9CZ05WQkFvTUIweHZaMmRwYm1jeEVqQVFCZ05WQkFzTUNVOXdaVzVUCmFHbG1kREVUTUJFR0ExVUVBd3dLYkc5bloybHVaeTFsY3pDQ0FpSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnSVAKQURDQ0Fnb0NnZ0lCQUp2eU5RY3ZvQmZVWm9zQmQ5bUg1ZjRBZ2tlTVRkUDFsNERtUS85MXk2NWVqMXR0am00YQpwc3NnVFdVSmFyMmkyYkt0eHJ0b1RTWHZVeENaZSt3L25JQjZ2Z0tSTHp5UmtlYkovam5ROG5neFl0dlVjc0RBCkpIRFVUcmUvbGRKdU50Ny8yNmlxeUdTY3J6SmF6a3lQY20zOGJta2ZVTmpmSjF5c1pRRHpkR1NxbTUrSWxRNEIKcGRTdGhUT3lpVTVUNC9wc2wwUkRjeWFBSHZqWTFocVUyTWEvMjBSVVZDYnl1WDVaamZrNGlxbFEvdTBDc01MSApVTXREcG45Tml1MUtsTTliTktQRE03a2NtYlY0MnNmVjdIYWNiczN4bmNQNlppVXdjVU0zd3lBWXlFcm4wbFZJClpBMzZ6RDFOaHhBZTkzcWF3MXRUb0lScER2NDhUUVVMRmZZb2RnejNwQjF2am90eWxCOXhLci9ORUFRT0xaYkgKSTBHZzlkSWJ6elJQWFBkcVFhQi9YWkZkRk1PWDN5L3ljdkg1THVNWGVZNmk0N2Q4cUpUUTdZZjhrYkZLYVJXRwpNL24zMk9zeVdoM0RWcTBrM1hCYVRHQnNFL3Y3LzRVNm1lMWxFSWlQZXV3ZjlzWnh6c0FsTkFhTG9adFVoU2o0CmZFemlaZkwzbGRleDcyWGRTWWJvVGVremRVSTBIUkozc3ZjTUFobHh0RCs3YXdiYkZZM3NHT0RVZGpFVjBCT24KRjUwY2FENzZ2ZWMwWk5WcXdiaEp0MUUvK3hxZGkwUDBtb21vRTlPalV0VnlGYVJyeU5Cd1lpTitJckFXTGNERAoyZlh0cWpyQm1CVmhVRXJHZjBSaEdEdUtzMlJ1c2N3bHpYMEtDbVQ4NmVOTk45NFZqcDVLN2FFakFnTUJBQUdqCmdnRVhNSUlCRXpBT0JnTlZIUThCQWY4RUJBTUNCYUF3Q1FZRFZSMFRCQUl3QURBZEJnTlZIU1VFRmpBVUJnZ3IKQmdFRkJRY0RBUVlJS3dZQkJRVUhBd0l3SFFZRFZSME9CQllFRklSYnpxT1BORVVYa1NzL0hrYlV4WTBFcGRSTApNQjhHQTFVZEl3UVlNQmFBRkVicUpQcHRPc0Qrc3lpdlVYWTM3SkJRYTArUU1JR1dCZ05WSFJFRWdZNHdnWXVICkJIOEFBQUdDQ1d4dlkyRnNhRzl6ZElJTlpXeGhjM1JwWTNObFlYSmphSUliWld4aGMzUnBZM05sWVhKamFDNWoKYkhWemRHVnlMbXh2WTJGc2doNWxiR0Z6ZEdsamMyVmhjbU5vTG5OaExYUmxiR1Z0WlhSeWVTNXpkbU9DTEdWcwpZWE4wYVdOelpXRnlZMmd1YzJFdGRHVnNaVzFsZEhKNUxuTjJZeTVqYkhWemRHVnlMbXh2WTJGc01BMEdDU3FHClNJYjNEUUVCRFFVQUE0SUNBUUJZWXF5QjZHeitKcFAwWFNzbEtNOU5kQzE1ZC9RUEtPQi9Cdk1vRTNQQ0R1N0QKTnBOUEFkb29OeDBia25lQi9kMmNFczNQdzZRd0hWVS9RaWRocC9TcjJ4aGx0bzJrZTRQS0R3ak1DTG5vMXpURgpheXZkeDEzTkN5NUp1RXh5ejFnbHJCY3RoTG16WFF3aE1jYWFLQWRnMDJ6V1RRdmJaNVJZS2hKTUpuMzg1a0NDClRwdTBuY3AxS3lmVlVDcEd0K3d6RmVhRkdiRXVabktaMTJJa2ltZlhNMUVzVzhCV216MGc3Q2s3aEg0bzhHQ0kKaDVMMWpkN1YyMWppUTFOKzEyTGl4UC9WQldUWklNcnFQTEVsYlp0czkvMUhMZFdadFpvbm9BN0ZKRDgwNDd6OQpuMnZkMldIK3g1N3Y0a2dWbnU2SWc5Y084WUZTbWlHbkhnUG5BQU03UW54ZERKUEh3VVg2L3duWmpjdGpBc1hyClVUOFNCOTlCR0xhZ3VVZDRZME1iQUx1c2kzdmFhZjJpT1VPdkdSbGFXT2xFcElleDVJUmJVVE01Y2NMSXNidW0KZERabnJMalJvdER2RFl0THNxTXhmOFFKVTNmQjdFWUtqSDZyUFpQRWRyVXZVVW5YNFBPOThRVm53MVRaeW5RSgprcmoxYjk0bHpZQ21DbVYralpHWDhPSmN1NkpGR2gyckpyY1RPUm9UT1BqYWRLL01CNGU5b0dkQWxWLzNoWjRYCkUrdSt4bkRhKzQxNllWS2FabmVIRzRCOGN6WGxKWllydUtZU09RekQ3ajNaMTIvSGFrVTNXazZYYWU2ZlJnMHMKYlhoNzBEeUlYU3RYdWVUSVE1MkhVVU80aFlsckp3bkpBdzZYRjUxSDVYblFxVVBxYjRyUGdJbndDT1BnWmc9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
      logging-es.key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUpRUUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQ1Nzd2dna25BZ0VBQW9JQ0FRQ2I4alVITDZBWDFHYUwKQVhmWmgrWCtBSUpIakUzVDlaZUE1a1AvZGN1dVhvOWJiWTV1R3FiTElFMWxDV3E5b3RteXJjYTdhRTBsNzFNUQptWHZzUDV5QWVyNENrUzg4a1pIbXlmNDUwUEo0TVdMYjFITEF3Q1J3MUU2M3Y1WFNiamJlLzl1b3FzaGtuSzh5CldzNU1qM0p0L0c1cEgxRFkzeWRjckdVQTgzUmtxcHVmaUpVT0FhWFVyWVV6c29sT1UrUDZiSmRFUTNNbWdCNzQKMk5ZYWxOakd2OXRFVkZRbThybCtXWTM1T0lxcFVQN3RBckRDeDFETFE2Wi9UWXJ0U3BUUFd6U2p3ek81SEptMQplTnJIMWV4Mm5HN044WjNEK21ZbE1IRkROOE1nR01oSzU5SlZTR1FOK3N3OVRZY1FIdmQ2bXNOYlU2Q0VhUTcrClBFMEZDeFgyS0hZTTk2UWRiNDZMY3BRZmNTcS96UkFFRGkyV3h5TkJvUFhTRzg4MFQxejNha0dnZjEyUlhSVEQKbDk4djhuTHgrUzdqRjNtT291TzNmS2lVME8ySC9KR3hTbWtWaGpQNTk5anJNbG9kdzFhdEpOMXdXa3hnYkJQNworLytGT3BudFpSQ0lqM3JzSC9iR2NjN0FKVFFHaTZHYlZJVW8rSHhNNG1YeTk1WFhzZTlsM1VtRzZFM3BNM1ZDCk5CMFNkN0wzREFJWmNiUS91MnNHMnhXTjdCamcxSFl4RmRBVHB4ZWRIR2crK3Izbk5HVFZhc0c0U2JkUlAvc2EKbll0RDlKcUpxQlBUbzFMVmNoV2thOGpRY0dJamZpS3dGaTNBdzluMTdhbzZ3WmdWWVZCS3huOUVZUmc3aXJOawpickhNSmMxOUNncGsvT25qVFRmZUZZNmVTdTJoSXdJREFRQUJBb0lDQUJpSzA4R2Z3eWc4Nnk1eE9yVm5aOURECnI3MG0zWkRBRStuYlUxUSs2NkV6aklndEE3OWNQbWUxVzdqTTlKbUhxWTh2UGhsOFhyZmJwRXoyZXNSQmRwWFoKdTFHWUc4RUNmOTI4YUdBYy9DdmlTZGFpNXJSakNOa2c4SXFHZ2tPdHlNRHJyMXdxRklPUkRSbDFwUVh6aFdTOQoxM3AvelM5MFh6TjhoaURTTDcwd0JISGxBdUJEYmgrOGR6d2RtdkpTell3NXpzeVZlT2ZVUGd1WHhJcEdacDlRCnptZEFoa1hpNlVKelFaNjVRVWxJVC9abzkveVBkYTJucGVwZS84QThmcExybmFzd0sxRzBxSlFnd3YyME14U3YKcGRpUGIrN0oxNDEreERSNThDRjdCUHFVNVVzNnExUnY1ZmkzM011eXMrdjlzMFVLTWpia2VkR1ZGK0gxVHExQgo0TWZCRlpHYW9PdVRIL3FYSXQ0UmFXWDZsOTlyVjA0NHAvMG9ZNW9EQlVqVnk0aFArTXlGUFZRa0lVVHpud1IzCkNQK204NDlSUklmNjZ5bnBSM1ROclpmUmFtZ3B0UUlaK2NzdmRHS3NITDJYNkdWS3NGaVltT214cWJMd0h5V0EKVmtlckRPb3FPQVJDb3Ixd1R5aUl0VGN2NjdEbFpkSXNjUG9OWjFSdFQ5MEJYOXYxVEE5ZW1OVnVEMEk5SVVYUgpRN0lZQWxEYlZFTXVrb1JqMHZWZUtFeDlyUURWaEoyZWQzdjg1L2ZUcU5JcldYUWhhMjMybUlBZFIvZldZUzZICnNnM3JmSXV0QjJhY2t4MlljY29OM1hqTUZGNkF4OXhtRWF2RXBGUkdpRWhmNmw3ZmIxN3FLUitHTVl0ZmErQXAKWmlMNTR4cDZvYmxMTFAzK29JTHhBb0lCQVFET1JJOTBlalgwN1RZbDlDaXRpd0xSWjRRRkIwQTBzSnRRZHQ3VQpBUDJoMEpRNnJicGhDNzB6OWl3RmFHQ1RlQWM3WGxoMkdWWUZmNkV1Q1kzY0Nmd2IxNmZkV1dPdTdpTzZBaW1UCjJYWjUxZ0t0eXhHZmJSVzFlVnNzcDJKdHhIREdsWS9McE5IMzE4Uk1nTzFiS2d3am9HemJOQWh6aHVmVTBTVUYKOVdVSElZamlJVUZyVURIUnRiem16bXY3cUdGRTJXVFJkamh0V2xTRmFIUko3bDQvMnFzK3hrWEVIRGxNOUVEVwpIQ0greGFIUm9TK2d5Q1o2MnBVMDdQaElrdkFlczAvRkhjVXp3SjBHZlB4KzBRMzhmMTlsMXdEeGdyT1ZmbnEyClc1Mk1RVHFna1M5V1E2dysrbFIrRFR0UlhkSGhXSThTa3pMYVFiMFNacVdheHM0SEFvSUJBUURCaTZYZnd1NWYKejVnRUhDeG1FRXR5VUdicTMwMGNMekt6YlB3YmRQK1BpR3R5K3ovVkh1OHFIYmJDb1htRTZDYUNIQWRoVHYwcwpkZm9HZHN3U01XSEEvd0JFV1pKRUtCdEVwSERmR0xPVjl2ZmpyK2JSeEE1NW0ycEtIMGdpZ3oyV1pPNU9xeUhmClpHVWRQTDYxUml3TkJMVnJtQmdBOGRUSi9hOG9KZS8rMXZDUEJHVzU4em01TmdPRWZjQ2l4ZzU5Ly9kTkxxcjcKSXZPeEJnaU1ZOFE2YXVodG5PRHZtc0ovd0dFZU9ySm5tRFRWdjVqcnFidjRXR1pKL05XZHpwYkkyb3I2WkZlOAp5cGFjZ1FvRGpWazV4T2ZvUVhCUlE3aUt3TzBjUXIvd2k5YTFVenRGV2Uvb3lYT2kralVyQjN0ZlY2RE1jOTZGCjBmRThMOVhaY00wRkFvSUJBQUV1SlQvK1h3YXF3TStReVJiTkg5UUE2cUY0dkNaUkNHSjZlNlhzNTRhZ2dlaWcKQzl2NFREbmE0NytZTEUxTHQ0YmdjRk1rcS9oV0ZaOEUwUG44V0tQMEpQTEFTekM2RGh4SFhPT0tzQUhjZHFGMQo4d0RkaCsxRTUzK202WXBGUUh2eWFTTTZLelZtMTZtMFp5ZEpZMDVrNFpxVGZxVGlsYnNEQTFvNFlENmRNNEpQCnZHY1h5MkV1MEFqbUQzb2VLWWhTVWlCY3M4LzBYMTF3RHBKSnVlSlZwdnN4K1Q0NUJ4N29tdUpld05jTFhIU3QKbm04bUZncEg2K2lrbm5zVDFDbm96c0VLL1pEaFBrVEdQRStoZEpvSVJJeDVvWGpBVGJUQ1I0TjVuTG9ydVdFbgowNFNEMkoxM296b2hhMEI0Ny9XQkl6aHcvUzZBaDh0dUtPNXN5c3NDZ2dFQVM4bmlYMWZXdmovdE9CYk1MLzlMCmUrME9FQVQzRGdWUlpqOVVEWEJvTG8xdC9lMXkxb0t4aHAxeUZvN2lwZSsrUEk2N09SaVVQUmZKbTBSanJ2QVYKWmx5MGZ3OVFIazVTTnpQcFd3TXlONVFwQjhpMnF3ZUozNGJEUFZrNGh3TTdWNndZUVVmMEVLVWdqeTFkUkdEQgpHU3Z4MnJzSkV6MmZaS1ZwTkdCK3RSejN3QmtwdUlJTTVZRElLZGFRVzIwUStiZ0UzLzFaU05Rcjl2TDAzL3lsCk4zYnJveGllWUZVS3VybmJqZG5RU0k2cWlkVG9EY2crYWdZN3I5ZEkwdTIxejlyOE53YVo4THluODRyNEgrSDIKd1k5Z2ZHczdqeWJrbWJqb1lIdW02NHZtdk1SbDNrZFVrYVJwR3JXOW9pYmc0Ym5QcHAvczBCd2d5YisxanRzRAovUUtDQVFBRWxFUkJySzE4T0NVTVhQdGdkWVIzTjlyYTJsMmZDeFJYSm9leE9ZekcyRXZpT0pROEd3L0hlbXpNCjRod0RFVjR4eGRCMExKd2dNdlo4UmcvUmNwaXg4bnVEVTVNZGxRL1dxcTFHQTB4dHUrT3gwUWlKem80ZzFvZkwKZVBNdkhVU0VOWkxRQVNFZ3duYjJvaVlCNHAvM3JvZFl0aktxT2ZCSW52MVZJVUF4UVBjOUNTVGZFRUhBYzVZcApvQmYrVmtsdll6QURIRDJTVytPQ1RydEZhOExYTTBJdllMcldkSTFPRExQNkQya0FKZTFPdGJiRklwMTNNQk55CndOczZTUFhKMllDS3N5OWw3T25lYUFxaTc1N3Q4SU9NZG9hdHNSQ1NRVDNDbEswa1VpZytrRXlCZWdMcmI1QkYKMFBZTE1ueTZZa2k5aUp2dU9rcGUxUVdBUHd6LwotLS0tLUVORCBQUklWQVRFIEtFWS0tLS0tCg==
    kind: Secret
EOF
