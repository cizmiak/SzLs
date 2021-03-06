USE [SpravaZmluv]
GO
/****** Object:  UserDefinedFunction [dbo].[SkolenieHTML]    Script Date: 26.01.2016 19:48:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetSkolenieEmailTable]
(
--DECLARE
	@skolenieID INT
) RETURNS NVARCHAR(MAX)
AS BEGIN
RETURN
CONVERT(NVARCHAR(MAX), (
SELECT
	'headerCell' AS [tr/th/@class], 'Školenie ID' AS [tr/th], class AS [tr/td/@class], SkolenieID AS [tr/td], ''
	,'headerCell' AS [tr/th/@class], 'Organizácia' AS [tr/th], class AS [tr/td/@class], Organizacia AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'Referencia' AS [tr/th], class AS [tr/td/@class], Referencia AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'Názov' AS [tr/th], class AS [tr/td/@class], Nazov AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'Typ' AS [tr/th], class AS [tr/td/@class], Typ AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'Druh' AS [tr/th], class AS [tr/td/@class], Druh AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'Uskutočnené' AS [tr/th], class AS [tr/td/@class], Uskutocnene AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'Nasledujúce' AS [tr/th], class AS [tr/td/@class], Nasledujuce AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'Miesto konania' AS [tr/th], class AS [tr/td/@class], MiestoKonania AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'Školenie pre koho' AS [tr/th], class AS [tr/td/@class], SkoleniePreKoho AS [tr/td], ''
FROM
	(
		SELECT
			'dataCell' as class
			,s.ID AS SkolenieID
			,o.Nazov AS Organizacia
			,s.Referencia
			,s.Nazov
			,st.Nazov AS Typ
			,sd.Nazov AS Druh
			,convert(varchar(20), s.Uskutocnene, 104) as Uskutocnene
			,convert(varchar(20), s.Nasledujuce, 104) as Nasledujuce
			,s.MiestoKonania
			,skp.Nazov AS SkoleniePreKoho
		FROM
			dbo.Skolenie s
			LEFT JOIN dbo.Organizacia o
				ON o.ID = s.OrganizaciaID
			LEFT JOIN dbo.SkolenieTyp st
				ON st.ID = s.TypID
			LEFT JOIN dbo.SkolenieDruh sd
				ON sd.ID = s.DruhID
			LEFT JOIN dbo.SkoleniePreKoho skp
				ON skp.ID = s.PreKohoID
		WHERE
			s.ID = @skolenieID
	) xmlPrepare
FOR XML PATH('tbody'), TYPE, ROOT('table')
))
END
GO
CREATE FUNCTION dbo.GetEmailStyle()
RETURNS NVARCHAR(255) AS
BEGIN
RETURN '<style type="text/css">
			body {font-family: Tahoma; font-size: 10pt;}
			.label {font-weight: bold; padding-right: 10px;}
			.bold {font-weight: bold;}
			th {font-weight: bold; text-align: left; padding-left: 10px;}
			td {padding-left: 10px;}
			.red {color: red;}
		 </style>'
END
GO
USE [SpravaZmluv]
GO
/****** Object:  StoredProcedure [dbo].[AOPNotification]    Script Date: 31.01.2016 20:43:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[AOPNotification] as
declare @today datetime = getdate()
declare @body varchar(max), @email varchar(1024)
declare @skolenieID int, @dni varchar(10), @organizaciaID int
declare cur cursor for
select
	id, dni, organizaciaID
from
	dbo.AOPSkolenieToNotificate(@today)

open cur
fetch next from cur into @skolenieID, @dni, @organizaciaID

while @@FETCH_STATUS = 0
begin

SET @body = '<!DOCTYPE html>
<html>
	<head>
		<style type="text/css">
			body {font-family: Tahoma; font-size: 10pt;}
			.label {font-weight: bold; padding-right: 10px;}
			.bold {font-weight: bold;}
			th {font-weight: bold; text-align: left; padding-left: 10px;}
			td {padding-left: 10px;}
			.red {color: red;}
		 </style>
	</head>
	<body>
O ' + @dni +' dní uplynie 5 rokov od vydania preukazov:<br/><br/>'
+ [dbo].[GetSkolenieEmailTable](@skolenieID) + '<br/>
--------------------------------------------------------------------------------------------------
<br/>E-mail kontaktných osôb:<br/>
' + report.GetKontaktnaOsobaEmail(@organizaciaID) + '<br/>
--------------------------------------------------------------------------------------------------
<br/><br/>Zoznam osôb, ktoré absolvovali školenie:<br/><br/>'
+ dbo.PosluchaciNaSkoleniHTML(@skolenieID, null) +
'<br/>Prosíme Vás o aktualizáciu zoznamu osôb ako aj návrh možného termínu periodického školenia.
<br/><br/>Ďakujem,
<br/>
	</body>
</html>'
--print @body
--print ''

set @email = dbo.SkolenieEmailToNotificate(@skolenieID)
EXEC msdb.dbo.sp_send_dbmail
@recipients = @email,
@copy_recipients = 'miroslav.hanzen@gmail.com;monika.hanzenova@gmail.com',
@blind_copy_recipients = 'matej.cizmarik@2ring.com',
@subject = 'Notifikácia AOP',
@body = @body,
@body_format = 'HTML'

fetch next from cur into @skolenieID, @dni, @organizaciaID
end

close cur
deallocate cur
go
drop function dbo.SkolenieHTML
go
ALTER FUNCTION [report].[PosluchaciNaSkoleniXML]
(
	@SkolenieID INT
)
RETURNS NVARCHAR(MAX)
AS BEGIN
DECLARE @result NVARCHAR(MAX)

SET @result =
CAST(
(SELECT
	' Priezvisko a meno' AS th, ''
	,' Titul' AS th, ''
	,' Pracovné zaradenie' AS th, ''
	,' Organizácia' AS th, ''
	,' Školenie ID' AS th, ''
	,' Referencia' AS th, ''
	,' Názov' AS th, ''
	,' Uskutočnené' AS th, ''
FOR XML PATH('tr'), TYPE)
AS NVARCHAR(MAX))
+
CAST(
(
SELECT
	td_class AS "td/@class", MenoCele AS td, ''
	,td_class AS "td/@class", Titul AS td, ''
	,td_class  AS "td/@class", PracovneZaradenie AS td, ''
	,td_class  AS "td/@class", Organizacia AS td, ''
	,td_class  AS "td/@class", SkolenieID AS td, ''
	,td_class  AS "td/@class", Referencia AS td, ''
	,td_class  AS "td/@class", Nazov AS td, ''
	,CASE
		WHEN GETDATE() - Uskutocnene < 365
		THEN 'red'
		ELSE td_class
	END AS "td/@class", CONVERT(VARCHAR(20), Uskutocnene, 104) AS td, ''
FROM
	(
		SELECT
			'common' AS td_class,
			ISNULL(p.Priezvisko + ' ', '') + ISNULL(p.Meno, '') AS MenoCele
			,p.Titul
			,pz.Nazov AS PracovneZaradenie
			,org.Nazov AS Organizacia
			,psp.SkolenieID
			,psp.Referencia
			,psp.Nazov
			,psp.Uskutocnene
		FROM
			dbo.SkoleniePosluchac sp
			INNER JOIN dbo.Posluchac p
				ON p.ID = sp.PosluchacID
			LEFT JOIN dbo.PracovneZaradenie pz
				ON pz.ID = p.PracovneZaradenieID
			LEFT JOIN dbo.Organizacia org
				ON org.ID = p.OrganizaciaID
			OUTER APPLY report.PosledneSkoleniePosluchaca(sp.SkolenieID, sp.PosluchacID) psp
		WHERE	
			sp.SkolenieID = @SkolenieID
	) xmlPrepare
ORDER BY
	MenoCele
FOR XML PATH('tr'), TYPE)
AS NVARCHAR(MAX))

SET @result = '<table>
' + @result + '
</table>'

RETURN @result
END
go
CREATE FUNCTION dbo.GetSkolenieHTML
(
	@SkolenieID INT
	,@Today DATETIME
)
RETURNS NVARCHAR(MAX) AS
BEGIN
DECLARE
	@html NVARCHAR(MAX)
	,@NasledujuceZa NVARCHAR(255)
	,@Lektor NVARCHAR(255)
	,@KontaktnaOsobaEmail NVARCHAR(255)
	,@Uskutocnene NVARCHAR(255)
	,@Typ NVARCHAR(255)
	,@Lehota NVARCHAR(255)

SELECT
	@Lektor = COALESCE(notifikovany.Priezvisko + ' ' + notifikovany.Meno, z.Priezvisko + ' ' + z.Meno, 'Nezadané')
	,@NasledujuceZa = ISNULL(CAST(CAST(FLOOR(CAST(s.Nasledujuce AS FLOAT)) - @Today AS INT) AS VARCHAR(20)), 'xy')
	,@Uskutocnene = ISNULL(CONVERT(VARCHAR(50), s.Uskutocnene, 104), 'Nezadané')
	,@KontaktnaOsobaEmail = ISNULL(report.GetKontaktnaOsobaEmail(s.OrganizaciaID), 'Nezadané')
	,@Lehota = ISNULL(CAST(YEAR(s.Nasledujuce) - YEAR(s.Uskutocnene) AS VARCHAR(5)), 'Nezadané')
	,@Typ = ISNULL(st.Nazov, 'Nezadané')
FROM
	dbo.Skolenie s
	LEFT JOIN dbo.Zamestnanec z
		ON z.ID = s.SkolitelID
		AND
		z.StavID != 2
	LEFT JOIN dbo.Zamestnanec notifikovany
		ON z.ID = s.NotifikovanyID
		AND
		z.StavID != 2
	LEFT JOIN dbo.SkolenieTyp st
		ON st.ID = s.TypID
WHERE
	s.ID = @SkolenieID

SET @html = '<!DOCTYPE html>
<html>
	<head>
		' + dbo.GetEmailStyle() + '
	</head>
	<body>
'

SET @html = @html + @Lektor + ',<br/>
Nasledujúce školenie sa má konať za ' + @NasledujuceZa + ' dní:<br/><br/>
'

SET @html = @html + dbo.GetSkolenieEmailTable(@SkolenieID) + '
<br/>
--------------------------------------------------------------------------------------------------
<br/>E-mail kontaktných osôb:<br/>
' + @KontaktnaOsobaEmail + '<br/>
--------------------------------------------------------------------------------------------------
<br/>
Dobrý deň,

<br/><br/>dňa ' + @Uskutocnene + ' sme vykonali, vo Vašej spoločnosti, školenie: <span class="bold">' + @Typ +
'</span>. Dovoľte, aby sme Vás touto cestou upozornili, že o ' + @NasledujuceZa +
' ' +
CASE
	WHEN ISNUMERIC(@NasledujuceZa) = 1 THEN
		CASE
			WHEN @NasledujuceZa = 1 THEN 'deň'
			WHEN @NasledujuceZa BETWEEN 2 AND 4 THEN 'dni'
			ELSE 'dní'
		END
	ELSE 'dní'
END +
' uplynie ' + @Lehota  + ' ročná lehota, v rámci ktorej by ste mali vykonať periodické školenie.
<br/>Zoznam osôb, ktoré absolvovali školenie:
<br/><br/>' + report.PosluchaciNaSkoleniXML(@SkolenieID) +
'
<br/>Prosíme Vás o aktualizáciu zoznamu osôb ako aj návrh možného termínu periodického školenia.

<br/><br/>Ďakujem,
<br/>
'

SET @html = @html + '
	</body>
</html>'

RETURN @html
END
go
CREATE FUNCTION dbo.SkolenieToNotificate
(
	@Today DATETIME
) RETURNS TABLE
AS RETURN
SELECT
	s.OrganizaciaID
	,s.ID AS SkolenieID
	,COALESCE(notifikovany.Email, skolitel.Email, 'miroslav.hanzen@gmail.com')
	+ ISNULL(';' + nadriadeny.Email, '')
	+ ISNULL(';' + zodpovedny.Email, '') AS Email
FROM
	dbo.Skolenie s
	LEFT JOIN dbo.Zamestnanec skolitel
		ON skolitel.ID = s.SkolitelID
		AND
		skolitel.StavID != 2
	LEFT JOIN dbo.Zamestnanec notifikovany
		ON skolitel.ID = s.NotifikovanyID
		AND
		skolitel.StavID != 2
	LEFT JOIN dbo.Zamestnanec nadriadeny
		ON nadriadeny.ID = skolitel.Nadriadeny
		AND
		nadriadeny.StavID != 2
	LEFT JOIN dbo.Zmluva zmluva
		ON zmluva.ID = s.ZmluvaID
	LEFT JOIN dbo.Zamestnanec zodpovedny
		ON zodpovedny.ID = zmluva.Zodpovedny
		AND
		zodpovedny.StavID != 2
WHERE
	FLOOR(CAST(s.Nasledujuce AS FLOAT)) - ISNULL(@Today, GETDATE()) IN (30,14)
go
CREATE FUNCTION dbo.GetHtmlBodyOpenTag()
RETURNS NVARCHAR(2047) AS
BEGIN
RETURN N'<!DOCTYPE html>
<html>
	<head>
		' + dbo.GetEmailStyle() + '
	</head>
	<body>
'
END
go
CREATE FUNCTION dbo.GetHtmlBodyCloseTag()
RETURNS NVARCHAR(255) AS
BEGIN
RETURN N'
	</body>
</html>'
END
go
USE [SpravaZmluv]
GO
/****** Object:  UserDefinedFunction [dbo].[GetSkolenieHTML]    Script Date: 01.02.2016 20:44:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetSkolenieBodyContent]
(
	@SkolenieID INT
	,@Today DATETIME
)
RETURNS NVARCHAR(MAX) AS
BEGIN

--DECLARE
--	@SkolenieID INT = 4768
--	,@Today DATETIME = FLOOR(CAST(GETDATE() AS FLOAT)) - 1

DECLARE
	@html NVARCHAR(MAX)
	,@NasledujuceZa NVARCHAR(255)
	,@Lektor NVARCHAR(255)
	,@KontaktnaOsobaEmail NVARCHAR(255)
	,@Uskutocnene NVARCHAR(255)
	,@Typ NVARCHAR(255)
	,@Lehota NVARCHAR(255)

SELECT
	@Lektor = COALESCE(notifikovany.Priezvisko + ' ' + notifikovany.Meno, z.Priezvisko + ' ' + z.Meno, 'Nezadané')
	,@NasledujuceZa = ISNULL(CAST(CAST(FLOOR(CAST(s.Nasledujuce AS FLOAT)) - @Today AS INT) AS VARCHAR(20)), 'xy')
	,@Uskutocnene = ISNULL(CONVERT(VARCHAR(50), s.Uskutocnene, 104), 'Nezadané')
	,@KontaktnaOsobaEmail = ISNULL(report.GetKontaktnaOsobaEmail(s.OrganizaciaID), 'Nezadané')
	,@Lehota = ISNULL(CAST(YEAR(s.Nasledujuce) - YEAR(s.Uskutocnene) AS VARCHAR(5)), 'Nezadané')
	,@Typ = ISNULL(st.Nazov, 'Nezadané')
FROM
	dbo.Skolenie s
	LEFT JOIN dbo.Zamestnanec z
		ON z.ID = s.SkolitelID
		AND
		z.StavID != 2
	LEFT JOIN dbo.Zamestnanec notifikovany
		ON z.ID = s.NotifikovanyID
		AND
		z.StavID != 2
	LEFT JOIN dbo.SkolenieTyp st
		ON st.ID = s.TypID
WHERE
	s.ID = @SkolenieID

SET @html = N'
'
SET @html = @html + @Lektor + ',<br/>
Nasledujúce školenie sa má konať za ' + @NasledujuceZa + ' dní:<br/><br/>
'
SET @html = @html + dbo.GetSkolenieEmailTable(@SkolenieID) + '
<br/>
--------------------------------------------------------------------------------------------------
<br/>E-mail kontaktných osôb:<br/>
' + @KontaktnaOsobaEmail + '<br/>
--------------------------------------------------------------------------------------------------
<br/>
Dobrý deň,

<br/><br/>dňa ' + @Uskutocnene + ' sme vykonali, vo Vašej spoločnosti, školenie: <span class="bold">' + @Typ +
'</span>. Dovoľte, aby sme Vás touto cestou upozornili, že o ' + @NasledujuceZa +
' ' +
CASE
	WHEN ISNUMERIC(@NasledujuceZa) = 1 THEN
		CASE
			WHEN @NasledujuceZa = 1 THEN 'deň'
			WHEN @NasledujuceZa BETWEEN 2 AND 4 THEN 'dni'
			ELSE 'dní'
		END
	ELSE 'dní'
END +
' uplynie ' + @Lehota  + ' ročná lehota, v rámci ktorej by ste mali vykonať periodické školenie.
<br/>Zoznam osôb, ktoré absolvovali školenie:
<br/><br/>' + report.PosluchaciNaSkoleniXML(@SkolenieID) +
'
<br/>Prosíme Vás o aktualizáciu zoznamu osôb ako aj návrh možného termínu periodického školenia.

<br/><br/>Ďakujem,
<br/>
'
--PRINT @html
RETURN @html
END
go
USE [SpravaZmluv]
GO
/****** Object:  StoredProcedure [dbo].[SkolenieNotification]    Script Date: 01.02.2016 20:03:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SkolenieNotification_Backup]
AS
--SET DATEFIRST 1
DECLARE
	@ID VARCHAR(200),
	@Referencia VARCHAR(200),
	@Nazov VARCHAR(200),
	@Uskutocnene VARCHAR(200),
	@Nasledujuce VARCHAR(200),
	@Lehota VARCHAR(200),
	@UcastCelkom VARCHAR(200),
	@Vyhovelo VARCHAR(200),
	@Nevyhovelo VARCHAR(200),
	@MiestoKonania VARCHAR(200),
	@SkoleniePreKoho VARCHAR(200),
	@Typ VARCHAR(200),
	@Druh VARCHAR(200),
	@FormaSkusania VARCHAR(200),
	@Organizacia VARCHAR(200),
	@Lektor VARCHAR(200),
	@PredsedaKomisie VARCHAR(200),
	@ClenKomisie1 VARCHAR(200),
	@ClenKomisie2 VARCHAR(200),
	@Email VARCHAR(200),
	@NasledujuceZa VARCHAR(200),
	@KontaktnaOsobaEmail VARCHAR(MAX),

	@body VARCHAR(MAX),
	@subject VARCHAR(100),
	@spravaZmluvURL VARCHAR(500),
	@aElement VARCHAR(1000),
	@Today DATETIME

SET @Today = FLOOR(CAST(GETDATE() AS FLOAT))
SET @subject = 'Notifikácia nasledujúceho školenia'
--SET @Today = '2014-09-01'
--SET @subject = '!!!test vymazte(ako by bolo 1.9.2014)!!! Notifikácia nasledujúceho školenia'

DELETE FROM dbo.SkolenieNotificated WHERE InsertedDateTime < @Today - 90

SELECT @spravaZmluvURL = Hodnota FROM dbo.Konfiguracia WHERE Nastavenie = 'SpravaZmluvURL'
SET @spravaZmluvURL = @spravaZmluvURL + '/#/'

DECLARE cur CURSOR FOR
SELECT
	s.ID AS ID
	,ISNULL(s.Referencia, 'Nezadané') AS Referencia
	,ISNULL(s.Nazov, 'Nezadané') AS  SkolenieNazov
	,ISNULL(CONVERT(VARCHAR(50), s.Uskutocnene, 104), 'Nezadané') AS Uskutocnene
	,CONVERT(VARCHAR(50), s.Nasledujuce, 104) AS Nasledujuce
	,ISNULL(CAST(YEAR(s.Nasledujuce) - YEAR(s.Uskutocnene) AS VARCHAR(5)), 'Nezadané') AS Lehota
	,ISNULL(CAST(s.UcastCelkom AS VARCHAR(50)), 'Nezadané') AS UcastCelkom
	,ISNULL(CAST(s.Vyhovelo AS VARCHAR(50)), 'Nezadané') AS Vyhovelo
	,ISNULL(CAST(s.Nevyhovelo AS VARCHAR(50)), 'Nezadané') AS Nevyhovelo
	,ISNULL(s.MiestoKonania, 'Nezadané') AS MiestoKonania
	,ISNULL(skp.Nazov, 'Nezadané') AS SkoleniePreKoho
	,ISNULL(st.Nazov, 'Nezadané')  AS Typ
	,ISNULL(sd.Nazov, 'Nezadané')  AS Druh
	,ISNULL(sfs.Nazov, 'Nezadané')  AS FormaSkusania
	,ISNULL(o.Nazov, 'Nezadané')  AS Organizacia
	,COALESCE(notifikovany.Priezvisko + ' ' + notifikovany.Meno, z.Priezvisko + ' ' + z.Meno, 'Nezadané')  AS Lektor
	,ISNULL(p.Priezvisko + ' ' + p.Meno, 'Nezadané')  AS PredsedaKomisie
	,ISNULL(c1.Priezvisko + ' ' + c1.Meno, 'Nezadané')  AS ClenKomisie1
	,ISNULL(c2.Priezvisko + ' ' + c2.Meno, 'Nezadané')  AS ClenKomisie2
	,COALESCE(notifikovany.Email, z.Email, 'miroslav.hanzen@gmail.com') + ISNULL(';' + nad.Email, '') + ISNULL(';' + zod.Email, '') AS Email
	,ISNULL(CAST(CAST(FLOOR(CAST(s.Nasledujuce AS FLOAT)) - @Today AS INT) AS VARCHAR(20)), 'xy') AS NasledujuceZa
	,ISNULL(report.GetKontaktnaOsobaEmail(s.OrganizaciaID), 'Nezadané') AS KontaktnaOsobaEmail
FROM
	dbo.Skolenie s
	LEFT JOIN dbo.Organizacia o
		ON o.ID = s.OrganizaciaID
	LEFT JOIN dbo.Zamestnanec z
		ON z.ID = s.SkolitelID
		AND
		z.StavID != 2
	LEFT JOIN dbo.Zamestnanec notifikovany
		ON z.ID = s.NotifikovanyID
		AND
		z.StavID != 2
	LEFT JOIN dbo.Zamestnanec nad
		ON nad.ID = z.Nadriadeny
		AND
		nad.StavID != 2
	LEFT JOIN dbo.Zamestnanec p
		ON p.ID = s.PredsedaKomisieID
	LEFT JOIN dbo.Zamestnanec c1
		ON c1.ID = s.ClenKomisie1ID
	LEFT JOIN dbo.Zamestnanec c2
		ON c2.ID = s.ClenKomisie2ID
	LEFT JOIN dbo.SkolenieTyp st
		ON st.ID = s.TypID
	LEFT JOIN dbo.SkolenieDruh sd
		ON sd.ID = s.DruhID
	LEFT JOIN dbo.SkolenieFormaSkusania sfs
		ON sfs.ID = s.FormaSkusaniaID
	LEFT JOIN dbo.SkoleniePreKoho skp
		ON skp.ID = s.PreKohoID
	LEFT JOIN dbo.Zmluva zml
		ON zml.ID = s.ZmluvaID
	LEFT JOIN dbo.Zamestnanec zod
		ON zod.ID = zml.Zodpovedny
		AND
		zod.StavID != 2
WHERE
	FLOOR(CAST(s.Nasledujuce AS FLOAT)) - @Today IN (30,14)
	/*2014-10-01 pondelokove notifikacie davame do precu*/
	--OR
	--s.Nasledujuce BETWEEN @Today AND @Today + 7
	--AND
	--DATEPART(DW, GETDATE()) = 1

OPEN cur

FETCH NEXT FROM cur INTO
	@ID,
	@Referencia,
	@Nazov,
	@Uskutocnene,
	@Nasledujuce,
	@Lehota,
	@UcastCelkom,
	@Vyhovelo,
	@Nevyhovelo,
	@MiestoKonania,
	@SkoleniePreKoho,
	@Typ,
	@Druh,
	@FormaSkusania,
	@Organizacia,
	@Lektor,
	@PredsedaKomisie,
	@ClenKomisie1,
	@ClenKomisie2,
	@Email,
	@NasledujuceZa,
	@KontaktnaOsobaEmail

WHILE @@FETCH_STATUS = 0
BEGIN

--SELECT
--	@ID,
--	@Referencia,
--	@Nazov,
--	@Uskutocnene,
--	@Nasledujuce,
--	@UcastCelkom,
--	@Vyhovelo,
--	@Nevyhovelo,
--	@MiestoKonania,
--	@SkoleniePreKoho,
--	@Typ,
--	@Druh,
--	@FormaSkusania,
--	@Organizacia,
--	@Lektor,
--	@PredsedaKomisie,
--	@ClenKomisie1,
--	@ClenKomisie2,
--	@Email,
--	@NasledujuceZa
	
SET @body = '<!DOCTYPE html>
<html>
	<head>
		<style type="text/css">
			body {font-family: Tahoma; font-size: 10pt;}
			.label {font-weight: bold; padding-right: 10px;}
			.bold {font-weight: bold;}
			th {font-weight: bold; text-align: left; padding-left: 10px;}
			td {padding-left: 10px;}
			.red {color: red;}
		 </style>
	</head>
	<body>
'

SET @body = @body + @Lektor + ',<br/>
Nasledujúce školenie sa má konať za ' + @NasledujuceZa + ' dní:<br/><br/>
'
--SET @aElement = '<a href="' + @spravaZmluvURL + 'SkoleniaVM?SkolenieID=' + @ID + '">Naviguj na skolenie...</a>'
--SET @aElement = NULL;

SET @body = @body + '
<table>
<tr>
<td class="label">ID: </td><td>' + @ID + '</td>
</tr>
<tr>
<td class="label">Organizácia:</td><td>' + @Organizacia + '</td>
</tr>
<tr>
<td class="label">Referencia:</td><td>' + @Referencia + '</td>
</tr>
<tr>
<td class="label">Názov:</td><td>' + @Nazov + '</td>
</tr>
<tr>
<td class="label">Typ:</td><td>' + @Typ + '</td>
</tr>
<tr>
<td class="label">Druh:</td><td> ' + @Druh + '</td>
</tr>
<tr>
<td class="label">Uskutočnené:</td><td>' + @Uskutocnene + '</td>
</tr>
<tr>
<td class="label">Nasledujúce:</td><td>' + @Nasledujuce + '</td>
</tr>
<tr>
<td class="label">Miesto konania:</td><td>' + @MiestoKonania + '</td>
</tr>
<tr>
<td class="label">Školenie pre koho:</td><td>' + @SkoleniePreKoho + '</td>
</tr>
</table>
<br/>
--------------------------------------------------------------------------------------------------
<br/>E-mail kontaktných osôb:<br/>
' + @KontaktnaOsobaEmail + '<br/>
--------------------------------------------------------------------------------------------------
<br/>
Dobrý deň,

<br/><br/>dňa ' + @Uskutocnene + ' sme vykonali, vo Vašej spoločnosti, školenie: <span class="bold">' + @Typ +
'</span>. Dovoľte, aby sme Vás touto cestou upozornili, že o ' + @NasledujuceZa +
' ' +
CASE
	WHEN ISNUMERIC(@NasledujuceZa) = 1 THEN
		CASE
			WHEN @NasledujuceZa = 1 THEN 'deň'
			WHEN @NasledujuceZa BETWEEN 2 AND 4 THEN 'dni'
			ELSE 'dní'
		END
	ELSE 'dní'
END +
' uplynie ' + @Lehota  + ' ročná lehota, v rámci ktorej by ste mali vykonať periodické školenie.
<br/>Zoznam osôb, ktoré absolvovali školenie:
<br/><br/>' + report.PosluchaciNaSkoleniXML(@ID) +
'
<br/>Prosíme Vás o aktualizáciu zoznamu osôb ako aj návrh možného termínu periodického školenia.

<br/><br/>Ďakujem,
<br/>
'

SET @body = @body + '
	</body>
</html>'

--PRINT ''
--PRINT @Email
--PRINT @subject
--PRINT @body

EXEC msdb.dbo.sp_send_dbmail
--@profile_name = 'cizmiak@gmail.com',
@recipients = @Email,
@copy_recipients = 'miroslav.hanzen@gmail.com;monika.hanzenova@gmail.com',

--@recipients = 'matej.cizmarik@2ring.com;miroslav.hanzen@gmail.com',
--@recipients = 'matej.cizmarik@2ring.com',
--@blind_copy_recipients = 'matej.cizmarik@2ring.com',

@subject = @subject,
@body = @body,
@body_format = 'HTML'

INSERT INTO dbo.SkolenieNotificated(ID, Referencia, SkolenieNazov, Uskutocnene, Nasledujuce, UcastCelkom, Vyhovelo, Nevyhovelo, MiestoKonania, SkoleniePreKoho, Typ, Druh, FormaSkusania, Organizacia, Lektor, PredsedaKomisie, ClenKomisie1, ClenKomisie2, Email, NasledujuceZa)
VALUES
(	@ID,
	@Referencia,
	@Nazov,
	@Uskutocnene,
	@Nasledujuce,
	@UcastCelkom,
	@Vyhovelo,
	@Nevyhovelo,
	@MiestoKonania,
	@SkoleniePreKoho,
	@Typ,
	@Druh,
	@FormaSkusania,
	@Organizacia,
	@Lektor,
	@PredsedaKomisie,
	@ClenKomisie1,
	@ClenKomisie2,
	@Email,
	@NasledujuceZa
)

FETCH NEXT FROM cur INTO
	@ID,
	@Referencia,
	@Nazov,
	@Uskutocnene,
	@Nasledujuce,
	@Lehota,
	@UcastCelkom,
	@Vyhovelo,
	@Nevyhovelo,
	@MiestoKonania,
	@SkoleniePreKoho,
	@Typ,
	@Druh,
	@FormaSkusania,
	@Organizacia,
	@Lektor,
	@PredsedaKomisie,
	@ClenKomisie1,
	@ClenKomisie2,
	@Email,
	@NasledujuceZa,
	@KontaktnaOsobaEmail
END

CLOSE cur
DEALLOCATE cur
go
ALTER PROCEDURE dbo.SkolenieNotification AS
DECLARE
	@Today DATETIME
	,@organizaciaID INT
	,@emailBody NVARCHAR(MAX)
	,@email NVARCHAR(MAX)
	,@emailTmp NVARCHAR(MAX)
	,@newLine NVARCHAR(3) = N'
'	,@mailSeparator NVARCHAR(255)
	,@subject NVARCHAR(255) = 'Notifikácia nasledujúceho školenia'
SET @mailSeparator =
	@newLine + N'--------------------------------------------------------------------------------------------------------' +
	@newLine + N'--------------------------------------------------------------------------------------------------------' +
	@newLine
SET @Today = FLOOR(CAST(GETDATE() AS FLOAT)) - 1

DECLARE @skolenia TABLE (OrganizaciaID INT, SkolenieID INT, Email NVARCHAR(255));

INSERT @skolenia(OrganizaciaID, SkolenieID, Email)
SELECT OrganizaciaID, SkolenieID, Email
FROM dbo.SkolenieToNotificate(@Today);

DECLARE organizacie CURSOR FOR
SELECT OrganizaciaID FROM @skolenia GROUP BY OrganizaciaID;
OPEN organizacie;

FETCH NEXT FROM organizacie INTO @organizaciaID;
WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT
		@emailBody = ISNULL(@emailBody + @mailSeparator, dbo.GetHtmlBodyOpenTag()) + dbo.GetSkolenieBodyContent(SkolenieID, @Today)
		,@emailTmp = ISNULL(@emailTmp + ';', '') + Email
	FROM @skolenia
	WHERE OrganizaciaID = @organizaciaID

	SET @emailBody = @emailBody + dbo.GetHtmlBodyCloseTag();

	SELECT
		@email = ISNULL(@email + ';', '') + Item
	FROM
		report.TableFromList(';', @emailTmp)
	GROUP BY
		Item

	PRINT @emailBody
	PRINT @email

EXEC msdb.dbo.sp_send_dbmail
--@recipients = @email,
--@copy_recipients = 'miroslav.hanzen@gmail.com;monika.hanzenova@gmail.com',
@recipients = 'matej.cizmarik@2ring.com',
@subject = @subject,
@body = @emailBody,
@body_format = 'HTML'

FETCH NEXT FROM organizacie INTO @organizaciaID;
END

CLOSE organizacie;
DEALLOCATE organizacie;
go