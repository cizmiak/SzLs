USE SpravaZmluv
GO
INSERT INTO dbo.Konfiguracia
SELECT 'PredvolenyFilterStavOrganizacie', 'Aktivna', NULL, NULL
WHERE
	NOT EXISTS (SELECT ID FROM dbo.Konfiguracia WHERE Nastavenie = 'PredvolenyFilterStavOrganizacie')
GO

INSERT INTO dbo.Konfiguracia
SELECT 'PredvolenyFilterStavZmluvy', 'Platná', NULL, NULL
WHERE
	NOT EXISTS (SELECT ID FROM dbo.Konfiguracia WHERE Nastavenie = 'PredvolenyFilterStavZmluvy')
GO


INSERT INTO dbo.Konfiguracia
SELECT 'ZmluvaPredmetTypUlohy', 'Predmet zmluvy', NULL, NULL
WHERE
	NOT EXISTS (SELECT ID FROM dbo.Konfiguracia WHERE Nastavenie = 'ZmluvaPredmetTypUlohy')
GO

INSERT INTO dbo.Konfiguracia
SELECT 'ZmluvaUvodnaPracaTypUlohy', 'Uvodna praca', NULL, NULL
WHERE
	NOT EXISTS (SELECT ID FROM dbo.Konfiguracia WHERE Nastavenie = 'ZmluvaUvodnaPracaTypUlohy')
GO

INSERT INTO dbo.Konfiguracia
SELECT 'ZmluvaVykonTypUlohy', 'Vykon', NULL, NULL
WHERE
	NOT EXISTS (SELECT ID FROM dbo.Konfiguracia WHERE Nastavenie = 'ZmluvaVykonTypUlohy')
GO

INSERT INTO dbo.Konfiguracia
SELECT 'UlohaStavVyriesene', 'Vyriesene', NULL, NULL
WHERE
	NOT EXISTS (SELECT ID FROM dbo.Konfiguracia WHERE Nastavenie = 'UlohaStavVyriesene')
GO

INSERT INTO dbo.Konfiguracia
SELECT 'PredvolenyVysledokSkolenia', 'Vyhovel', NULL, NULL
WHERE
	NOT EXISTS (SELECT ID FROM dbo.Konfiguracia WHERE Nastavenie = 'PredvolenyVysledokSkolenia')
GO

IF NOT EXISTS(SELECT * FROM sys.computed_columns WHERE name = 'IdComputed' AND OBJECT_ID('dbo.Skolenie') = OBJECT_ID)
ALTER TABLE dbo.Skolenie ADD IdComputed AS ID
GO
IF NOT EXISTS(SELECT * FROM sys.computed_columns WHERE name = 'IdVarchar' AND OBJECT_ID('dbo.Skolenie') = OBJECT_ID)
ALTER TABLE dbo.Skolenie ADD IdVarchar AS CAST(ID AS VARCHAR(10))
GO

IF NOT EXISTS(SELECT * FROM sys.computed_columns WHERE name = 'IdComputed' AND OBJECT_ID('dbo.Zmluva') = OBJECT_ID)
ALTER TABLE dbo.Zmluva ADD IdComputed AS ID
GO
IF NOT EXISTS(SELECT * FROM sys.computed_columns WHERE name = 'IdVarchar' AND OBJECT_ID('dbo.Zmluva') = OBJECT_ID)
ALTER TABLE dbo.Zmluva ADD IdVarchar AS CAST(ID AS VARCHAR(10))
GO

IF NOT EXISTS(SELECT * FROM sys.computed_columns WHERE name = 'IdComputed' AND OBJECT_ID('dbo.Uloha') = OBJECT_ID)
ALTER TABLE dbo.Uloha ADD IdComputed AS ID
GO
IF NOT EXISTS(SELECT * FROM sys.computed_columns WHERE name = 'IdVarchar' AND OBJECT_ID('dbo.Uloha') = OBJECT_ID)
ALTER TABLE dbo.Uloha ADD IdVarchar AS CAST(ID AS VARCHAR(10))
GO

IF NOT EXISTS(SELECT * FROM sys.computed_columns WHERE name = 'IdComputed' AND OBJECT_ID('dbo.Posluchac') = OBJECT_ID)
ALTER TABLE dbo.Posluchac ADD IdComputed AS ID
GO
IF NOT EXISTS(SELECT * FROM sys.computed_columns WHERE name = 'IdVarchar' AND OBJECT_ID('dbo.Posluchac') = OBJECT_ID)
ALTER TABLE dbo.Posluchac ADD IdVarchar AS CAST(ID AS VARCHAR(10))
GO

IF OBJECT_ID('dbo.GetOrganizaciaNazov') IS NULL
EXEC('CREATE FUNCTION dbo.GetOrganizaciaNazov (@OrganizaciaID INT) RETURNS VARCHAR(100) AS BEGIN RETURN (SELECT o.Nazov FROM dbo.Organizacia o WHERE o.ID = @OrganizaciaID) END')
GO

IF NOT EXISTS(SELECT * FROM sys.computed_columns WHERE name = 'OrganizaciaNazov' AND OBJECT_ID('dbo.Posluchac') = OBJECT_ID)
ALTER TABLE dbo.Posluchac ADD OrganizaciaNazov AS dbo.GetOrganizaciaNazov(OrganizaciaID)
GO