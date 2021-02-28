import requests
import time

sensors_url = 'http://localhost:8010/proxy/sky/cloud/ckllblsx3001i94ua08sn5xrk/manage_sensor/sensors'

## Create 4 Sensors
create_url = 'http://localhost:8010/proxy/sky/event/ckllblsx3001i94ua08sn5xrk/temp/sensor/new_sensor'
t1 = {'SensorName': 'Test1'}
t2 = {'SensorName': 'Test2'}
t3 = {'SensorName': 'Test3'}
t4 = {'SensorName': 'Test4'}

res1 = requests.post(create_url, data = t1)
res2 = requests.post(create_url, data = t2)
res3 = requests.post(create_url, data = t3)
res4 = requests.post(create_url, data = t4)

res_query = requests.get(sensors_url)
eci1 = res_query.text.split('\"')[1]
eci2 = res_query.text.split('\"')[5]
eci3 = res_query.text.split('\"')[9]
eci4 = res_query.text.split('\"')[13]
print("------------- Sensors ------------------")
print(res_query.text)
print("----------------------------------------")
time.sleep(15)

## Test setup
profile_url = 'http://localhost:8010/proxy/sky/cloud/ckllblsx3001i94ua08sn5xrk/manage_sensor/query_sensor_profile'
setup_string = requests.get(url = profile_url, params = {'eci':eci1})
print("------------- Sensors Profile Test1 ------------------")
print(setup_string.text)
print("------------------------------------------------------")

setup_string = requests.get(url = profile_url, params = {'eci':eci2})
print("------------- Sensors Profile Test2 ------------------")
print(setup_string.text)
print("------------------------------------------------------")

setup_string = requests.get(url = profile_url, params = {'eci':eci3})
print("------------- Sensors Profile Test3 ------------------")
print(setup_string.text)
print("------------------------------------------------------")

setup_string = requests.get(url = profile_url, params = {'eci':eci4})
print("------------- Sensors Profile Test4 ------------------")
print(setup_string.text)
print("------------------------------------------------------")

## Test temperatures
temp_url = 'http://localhost:8010/proxy/sky/cloud/ckllblsx3001i94ua08sn5xrk/manage_sensor/query_temp'
print("------------- Temps Test1 ------------------")
temps_string = requests.get(url = temp_url, params = {'eci':eci1})
print(temps_string.text)
print("--------------------------------------------")

print("------------- Temps Test2 ------------------")
temps_string = requests.get(url = temp_url, params = {'eci':eci2})
print(temps_string.text)
print("--------------------------------------------")

print("------------- Temps Test3 ------------------")
temps_string = requests.get(url = temp_url, params = {'eci':eci3})
print(temps_string.text)
print("--------------------------------------------")

print("------------- Temps Test4 ------------------")
temps_string = requests.get(url = temp_url, params = {'eci':eci4})
print(temps_string.text)
print("--------------------------------------------")

query_url = 'http://localhost:8010/proxy/sky/cloud/ckllblsx3001i94ua08sn5xrk/manage_sensor/query_temps'
print("------------- Query_temps ------------------")
res_query = requests.get(query_url)
print(res_query.text)
print("--------------------------------------------")

## Delete one child
delete_url = 'http://localhost:8010/proxy/sky/event/ckllblsx3001i94ua08sn5xrk/temp/sensor/unneeded_sensor'
delete1 = {'name': 'Test1'}
requests.post(delete_url, data = delete1)

print("------------- Sensors After Deletion ------------------")
res_query = requests.get(sensors_url)
print(res_query.text)
print("-------------------------------------------------------")

## Query Children
print("------------- Query_temps ------------------")
res_query = requests.get(query_url)
print(res_query.text)
print("--------------------------------------------")


