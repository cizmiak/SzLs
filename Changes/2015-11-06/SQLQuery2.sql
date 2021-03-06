USE [SpravaZmluv]
GO
/****** Object:  UserDefinedFunction [dbo].[AOPSkolenieToNotificate]    Script Date: 06.11.2015 11:50:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[AOPSkolenieToNotificate]
(@today datetime) returns @skolenia table
(
	id int,
	dni varchar(10),
	organizaciaID int
) AS
begin

set @today = FLOOR(CAST(@today AS FLOAT))

insert @skolenia (id, dni, organizaciaID)
select
	s.ID,
	str(cast(FLOOR
	(
		CAST
		(
			DATEADD(YEAR, 5, ISNULL(sp.PreukazVydany, s.PreukazyVydane)) AS FLOAT
		)
	) - @today as float)) as dni,
	s.OrganizaciaID
from
	dbo.SkoleniePosluchac sp
	inner join dbo.Skolenie s
		on s.ID = sp.SkolenieID
where
	FLOOR
	(
		CAST
		(
			DATEADD(YEAR, 5, ISNULL(sp.PreukazVydany, s.PreukazyVydane)) AS FLOAT
		)
	) - @today IN (30,14)
group by
	s.ID,
	FLOOR
	(
		CAST
		(
			DATEADD(YEAR, 5, ISNULL(sp.PreukazVydany, s.PreukazyVydane)) AS FLOAT
		)
	) - @today,
	s.OrganizaciaID
return

end
GO
/****** Object:  UserDefinedFunction [dbo].[PosluchaciNaSkoleniHTML]    Script Date: 06.11.2015 11:50:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[PosluchaciNaSkoleniHTML]
(
--DECLARE
	@skolenieID INT,
	@organizaciaID INT = NULL
) RETURNS NVARCHAR(MAX)
AS BEGIN

DECLARE @result NVARCHAR(MAX)
SET @result = CONVERT (NVARCHAR(MAX), (
SELECT
'table-table' AS [@class],
'tableHeader' AS [thead/@class],
(
	SELECT
		'headerRow' AS [@class]
		,'headerCell' AS [th/@class], 'SkolenieID' AS th, ''
		,'headerCell' AS [th/@class], 'Referencia' AS th, ''
		,'headerCell'  AS [th/@class], 'Nazov' AS th, ''
		,'headerCell'  AS [th/@class], 'Uskutocnene' AS th, ''
		,'headerCell'  AS [th/@class], 'Druh' AS th, ''
		,'headerCell'  AS [th/@class], 'Typ' AS th, ''
		,'headerCell'  AS [th/@class], 'PreukazVydany' AS th, ''
		,'headerCell'  AS [th/@class], 'PreukazVydal' AS th, ''
		,'headerCell'  AS [th/@class], 'Posluchac' AS th, ''
		,'headerCell'  AS [th/@class], 'Titul' AS th, ''
		,'headerCell'  AS [th/@class], 'PracovneZaradenie' AS th, ''
		,'headerCell'  AS [th/@class], 'Organizacia' AS th, ''
	FOR XML PATH('tr'), TYPE
) thead,
'tableBody' AS [tbody/@class],
(
	SELECT
		'row' AS [@class]
		,class AS [td/@class], SkolenieID AS td, ''
		,class AS [td/@class], Referencia AS td, ''
		,class  AS [td/@class], Nazov AS td, ''
		,class  AS [td/@class], Uskutocnene AS td, ''
		,class  AS [td/@class], Druh AS td, ''
		,class  AS [td/@class], Typ AS td, ''
		,class  AS [td/@class], PreukazVydany AS td, ''
		,class  AS [td/@class], PreukazVydal AS td, ''
		,class  AS [td/@class], Posluchac AS td, ''
		,class  AS [td/@class], Titul AS td, ''
		,class  AS [td/@class], PracovneZaradenie AS td, ''
		,class  AS [td/@class], Organizacia AS td, ''
	FROM
		(
			SELECT
				'dataCell' as class
				,sp.SkolenieID
				,s.Referencia
				,s.Nazov
				,convert(varchar(20), s.Uskutocnene, 104) as Uskutocnene
				,sd.Nazov as Druh
				,st.Nazov as Typ
				,CONVERT(varchar(20), ISNULL(sp.PreukazVydany, s.PreukazyVydane), 104) AS PreukazVydany
				,ISNULL(sp.PreukazVydal, s.PreukazyVydal) AS PreukazVydal
				,ISNULL(p.Priezvisko + ' ', '') + ISNULL(p.Meno, '') AS Posluchac
				,p.Titul
				,pz.Nazov AS PracovneZaradenie
				,o.Nazov AS Organizacia
			FROM
				dbo.SkoleniePosluchac sp
				inner join dbo.Skolenie s
					on s.ID = sp.SkolenieID
				inner join dbo.Posluchac p
					on p.ID = sp.PosluchacID
				left join dbo.Organizacia o
					on o.ID = p.OrganizaciaID
				left join dbo.PracovneZaradenie pz
					on pz.ID = p.PracovneZaradenieID
				left join dbo.SkolenieDruh sd
					on sd.ID = s.DruhID
				left join dbo.SkolenieTyp st
					on st.ID = s.TypID
			WHERE
				sp.SkolenieID = @skolenieID
				AND
				(
					p.OrganizaciaID = @organizaciaID
					OR
					@organizaciaID IS NULL
				)
		) xmlPrepare
	FOR XML PATH('tr'), TYPE
) tbody
FOR XML PATH('table'), TYPE
))

--PRINT @result
RETURN @result
END
GO
/****** Object:  UserDefinedFunction [dbo].[SkolenieEmailToNotificate]    Script Date: 06.11.2015 11:50:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[SkolenieEmailToNotificate]
(@skolenieID int) returns varchar(1024)
as begin 
return (
select
	COALESCE(notifikovany.Email, z.Email, 'miroslav.hanzen@gmail.com') + ISNULL(';' + nad.Email, '') + ISNULL(';' + zod.Email, '') AS Email
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
	LEFT JOIN dbo.Zmluva zml
		ON zml.ID = s.ZmluvaID
	LEFT JOIN dbo.Zamestnanec zod
		ON zod.ID = zml.Zodpovedny
		AND
		zod.StavID != 2
where
	s.ID = @skolenieID
)
end
GO
/****** Object:  UserDefinedFunction [dbo].[SkolenieHTML]    Script Date: 06.11.2015 11:50:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[SkolenieHTML]
(
--DECLARE
	@skolenieID INT
) RETURNS NVARCHAR(MAX)
AS BEGIN
RETURN
CONVERT(NVARCHAR(MAX), (
SELECT
	'headerCell' AS [tr/th/@class], 'SkolenieID' AS [tr/th], class AS [tr/td/@class], SkolenieID AS [tr/td], ''
	,'headerCell' AS [tr/th/@class], 'Organizacia' AS [tr/th], class AS [tr/td/@class], Organizacia AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'Referencia' AS [tr/th], class AS [tr/td/@class], Referencia AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'Nazov' AS [tr/th], class AS [tr/td/@class], Nazov AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'Typ' AS [tr/th], class AS [tr/td/@class], Typ AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'Druh' AS [tr/th], class AS [tr/td/@class], Druh AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'Uskutocnene' AS [tr/th], class AS [tr/td/@class], Uskutocnene AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'Nasledujuce' AS [tr/th], class AS [tr/td/@class], Nasledujuce AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'MiestoKonania' AS [tr/th], class AS [tr/td/@class], MiestoKonania AS [tr/td], ''
	,'headerCell'  AS [tr/th/@class], 'SkoleniePreKoho' AS [tr/th], class AS [tr/td/@class], SkoleniePreKoho AS [tr/td], ''
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
/****** Object:  UserDefinedFunction [report].[GetKontaktnaOsobaEmail]    Script Date: 06.11.2015 11:50:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [report].[GetKontaktnaOsobaEmail]
(@OrganizaciaID INT)
RETURNS VARCHAR(MAX) AS
BEGIN
	DECLARE
		@emails VARCHAR(MAX)
		--,@matkaID INT

	SELECT
		@emails = ISNULL(@emails + ';', '') + ko.Mail
	FROM
		dbo.KontaktnaOsoba ko
	WHERE
		OrganizaciaID = @OrganizaciaID

	--SELECT @matkaID = Matka FROM dbo.Organizacia WHERE ID = @OrganizaciaID

	RETURN ISNULL(@emails, 'Nezadané') --+ report.GetKontaktnaOsobaEmail(@matkaID)
END
GO
/****** Object:  StoredProcedure [dbo].[AOPNotification]    Script Date: 06.11.2015 11:50:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[AOPNotification] as
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
+ [dbo].[SkolenieHTML](@skolenieID) + '<br/>
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
GO
/****** Object:  StoredProcedure [dbo].[SendSkolbozNotification]    Script Date: 06.11.2015 11:50:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[SendSkolbozNotification]
AS
EXEC [dbo].[UlohaNotification]
EXEC [dbo].[ZmluvaNotification]
EXEC [dbo].[SkolenieNotification]
EXEC [dbo].[AOPNotification]
GO
