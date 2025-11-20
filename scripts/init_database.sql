/*
Create db and schemas, if db with a name 'DataWarehouse' already exists DROP it and create a new one with 3 schemas, bronze, silver and gold.

WARNING: Drop entire 'DataWarehouse' and all data will be lost
*/

use master;
go
if exists(select 1 from sys.databases where name ='DataWarehouse')
	begin
		alter database DataWarehouse set SINGLE_USER WITH ROLLBACK IMMEDIATE;
		DROP DATABASE DataWarehouse;
	end;
go
create database DataWarehouse;
go
use DataWarehouse;
go
CREATE SCHEMA bronze;
go
CREATE SCHEMA silver;
go
CREATE SCHEMA gold;
go
