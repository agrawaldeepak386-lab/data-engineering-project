
create catalog if not exists dev_dep;
create schema if not exists dev_dep.bronze;
create schema if not exists dev_dep.silver;
create schema if not exists dev_dep.gold;
create volume if not exists dev_dep.bronze.raw;

create catalog if not exists uat_dep;
create schema if not exists uat_dep.bronze;
create schema if not exists uat_dep.silver;
create schema if not exists uat_dep.gold;
create volume if not exists uat_dep.bronze.raw;

create catalog if not exists prod_dep;
create schema if not exists prod_dep.bronze;
create schema if not exists prod_dep.silver;
create schema if not exists prod_dep.gold;
create volume if not exists prod_dep.bronze.raw;