USE SpravaZmluv
GO
ALTER FUNCTION dbo.GetTrainingType
(
	@trainingId INT
) RETURNS NVARCHAR(50)
AS
BEGIN
	RETURN
	(
		SELECT
			Nazov
		FROM
			dbo.SkolenieTyp
		WHERE
			ID = (SELECT TypID FROM dbo.Skolenie WHERE ID = @trainingId)
	)
END
GO
ALTER PROCEDURE [dbo].[AOPNotification]
(
	@today DATETIME = NULL
)
AS
/*
declare @today datetime = '2019-06-7'
declare @enddate datetime = @today-2

while @today > @enddate
begin
	print @today
	exec [dbo].[AOPNotification] @today
	set @today-=1
end
*/

SET @today = ISNULL(@today, getdate())

DECLARE
	@body VARCHAR(max),
	@email VARCHAR(1024)

DECLARE
	@skolenieID INT,
	@dni VARCHAR(10),
	@organizaciaID INT,
	@trainingTable NVARCHAR(MAX),
	@type NVARCHAR(MAX),
	@organization NVARCHAR(MAX),
	@organizationEmail NVARCHAR(MAX),
	@subject NVARCHAR(MAX) = 'Notifikácia Aktualizačnej odbornej prípravy - ${type} - ${organization}'

DECLARE cur CURSOR FOR
SELECT
	id, dni, organizaciaID
FROM
	dbo.AOPSkolenieToNotificate(@today)

OPEN cur
FETCH NEXT FROM cur INTo @skolenieID, @dni, @organizaciaID

WHILE @@FETCH_STATUS = 0
BEGIN

SET @type = dbo.GetTrainingType(@skolenieID)

SELECT
	@organization = Nazov,
	@organizationEmail = ISNULL(Mail, 'Nezadané')
FROM
	dbo.Organizacia
WHERE
	ID = @organizaciaID

SET @trainingTable = [dbo].[GetSkolenieEmailTable](@skolenieID)

SET @subject = REPLACE(@subject, '${type}', @type)
SET @subject = REPLACE(@subject, '${organization}', @organization)

SET @body = '<!DOCTYPE html>
<html>
	<head>
		<style type="text/css">
			body {font-family: Tahoma; font-size: 10pt;}
			.label {font-weight: bold; padding-right: 10px;}
			.bold {font-weight: bold;}
			th {font-weight: bold; text-align: left; padding-left: 10px;}
			td {padding-left: 10px;}
			.line-through {text-decoration: line-through;}
			.red {color: red;}
		 </style>
	</head>
	<body>
O ' + @dni +' dní uplynie 5 rokov od vydania preukazov:<br/><br/>'
+ @trainingTable + '<br/>
--------------------------------------------------------------------------------------------------
<br/>E-mail kontaktných osôb:<br/>
' + report.GetKontaktnaOsobaEmail(@organizaciaID) + '<br/>
<br/>E-mail organizácie:<br/>
' + @organizationEmail + '<br/>
--------------------------------------------------------------------------------------------------
<br/><br/>
Dobrý deň,
<br/><br/>
Dovoľte, aby sme vás upozornili, na blížiaci sa termín vykonania <span class="bold">Aktualizačnej odbornej prípravy (AOP)</span> pre držiteľov preukazu na ' + @type + '.
<span class="bold">AOP</span> by sa mala vykonať do 5 - tich rokov odo dňa vydania preukazu,
ktorý máte vyznačený na preukaze, alebo tento údaj nájdete aj v našej tabuľke dole v stĺpci označenom ako "<span class="bold">PreukazVydany</span>".
Upozorňujeme, že do termínu vykonania <span class="bold">AOP</span> musí byť vykonaná aj opakovaná <span class="bold">lekárska prehliadka</span> vo vzťahu k práci.
V opačnom prípade preukaz stráca platnosť.
Túto notifikáciu vám posielame 45 dní pred uplynutím lehoty na vykonanie <span class="bold">AOP</span>, aby ste mali dostatok času si pripraviť všetko potrebné.
<br/><br/>Zoznam osôb, ktoré absolvovali školenie:<br/><br/>'
+ dbo.PosluchaciNaSkoleniHTML(@skolenieID, null) +
'<br/>Prosíme Vás o aktualizáciu zoznamu osôb ako aj návrh možného termínu periodického školenia.
<br/><br/>Ďakujem,
<br/>
	</body>
</html>'
--prINT @body
--prINT ''

SET @email = dbo.SkolenieEmailToNotificate(@skolenieID)
EXEC msdb.dbo.sp_send_dbmail
@recipients = @email,
@copy_recipients = 'miroslav.hanzen@gmail.com;monika.hanzenova@gmail.com',
--@blind_copy_recipients = 'matej.cizmarik@2ring.com',
@subject = @subject,
@body = @body,
@body_format = 'HTML'

FETCH NEXT FROM cur INTo @skolenieID, @dni, @organizaciaID
END

CLOSE cur
DEALLOCATE cur
GO
ALTER PROCEDURE [dbo].[SendOfferAfter16Months]
AS

DECLARE @Today DATETIME = FLOOR(CAST(GETDATE() AS FLOAT))

DECLARE
	@OfferId INT,
	@OrganizationId INT,
	@OrganizationName VARCHAR(100),
	@Subject VARCHAR(255),
	@Body VARCHAR(MAX),
	@SentDate DATETIME,
	@RealizationDate DATETIME,
	@Price VARCHAR(32),
	@OrganizationEmail VARCHAR(100),
	@ContactPersonEmail VARCHAR(MAX),
	@ResponsibleEmail VARCHAR(100),
	@OfferState VARCHAR(50)
	
DECLARE cur CURSOR FAST_FORWARD FOR
SELECT
	offers.Id AS OfferId,
	offers.OrganizationId,
	ISNULL(organization.Nazov, 'Nezadané')  AS OrganizationName,
	ISNULL(offers.[Subject], 'Nezadané') AS [Subject],
	ISNULL(offers.Body, 'Nezadané') AS Body,
	offers.SentDate,
	offers.RealizationDate,
	ISNULL(CAST(offers.Price AS VARCHAR(32)) + ' €', 'Nezadané') AS Price,
	ISNULL(organization.Mail, 'Nezadané') AS OrganizationEmail,
	report.GetKontaktnaOsobaEmail(offers.OrganizationId) AS ContactPersonEmail,
	responsible.Email AS ResponsibleEmail,
	offerStates.Name AS OfferState
FROM
	dbo.Offers offers
	LEFT JOIN dbo.Organizacia organization
		ON organization.ID = offers.OrganizationId
	LEFT JOIN dbo.Zamestnanec responsible
		ON responsible.ID = offers.ResponsibleEmployeeId
	LEFT JOIN dbo.OfferStates offerStates
		ON offerStates.Id = offers.OfferStateId
WHERE
	DATEADD(MONTH, 16, FLOOR(CAST(offers.RealizationDate AS FLOAT))) = @Today

OPEN cur
FETCH NEXT FROM cur INTO
	@OfferId,
	@OrganizationId,
	@OrganizationName,
	@Subject,
	@Body,
	@SentDate,
	@RealizationDate,
	@Price,
	@OrganizationEmail,
	@ContactPersonEmail,
	@ResponsibleEmail,
	@OfferState

WHILE @@FETCH_STATUS = 0
BEGIN
	--SELECT
	--	@OfferId AS OfferId,
	--	@OrganizationId AS OrganizationId,
	--	@Subject AS Subject,
	--	@Body AS Body,
	--	@SentDate AS SentDate,
	--	@Price AS Price,
	--	@OrganizationEmail AS OrganizationEmail,
	--	@ContactPersonEmail AS ContactPersonEmail,
	--	@ResponsibleEmail AS ResponsibleEmail

	DECLARE @Contacts VARCHAR(MAX) = '
--------------------------------------------------------------------------------------------------
<br/>E-mail kontaktných osôb:<br/>
' + @ContactPersonEmail + '<br/>
<br/>Názov organizácie:<br/>
<b>' + @OrganizationName + '</b><br/>
<br/>E-mail organizácie:<br/>
' + @OrganizationEmail + '<br/>
--------------------------------------------------------------------------------------------------
<br/>
<br/>
'
	DECLARE @18MonthAfter DATETIME = DATEADD(MONTH, 18, @RealizationDate) 

	SET @Subject = @Subject + ' - Opakovany audit posudenia rizik'
	SET @Subject = REPLACE(@Subject, '${OfferId}', @OfferId)
	SET @Subject = REPLACE(@Subject, '${OrganizationName}', @OrganizationName)

	SET @Body = '<br/><b>${18MonthAfter}</b> uplynie 18 mesiacov od datumu realizacie.'
	SET @Body += '<br/><b>Datum Realizacie:</b> ${RealizationDate}'
	SET @Body += '<br/><b>Ponuka Id:</b> ${OfferId}'
	SET @Body += '<br/><b>Organizacia:</b> ${OrganizationName}'
	SET @Body += '<br/><b>Stav:</b> ${OfferState}'


	SET @Body = REPLACE(@Body, '${OfferId}', @OfferId)
	SET @Body = REPLACE(@Body, '${Price}', @Price)

	IF @OrganizationName IS NOT NULL
		SET @Body = REPLACE(@Body, '${OrganizationName}', @OrganizationName)

	IF @RealizationDate IS NOT NULL
		SET @Body = REPLACE(@Body, '${RealizationDate}', @RealizationDate)

	IF @SentDate IS NOT NULL
		SET @Body = REPLACE(@Body, '${SentDate}', @SentDate)

	IF @18MonthAfter IS NOT NULL
		SET @Body = REPLACE(@Body, '${18MonthAfter}', @18MonthAfter)

	IF @OfferState IS NOT NULL
		SET @Body = REPLACE(@Body, '${OfferState}', @OfferState)

	SET @Body = dbo.GetHtmlBodyOpenTag() + @Contacts + @Body + dbo.GetHtmlBodyCloseTag()

	EXEC msdb.dbo.sp_send_dbmail
		@recipients = 'miroslav.hanzen@gmail.com;monika.hanzenova@gmail.com',
		--@blind_copy_recipients = 'matej.cizmarik@2ring.com',
		@subject = @Subject,
		@body = @Body,
		@body_format = 'HTML'

	FETCH NEXT FROM cur INTO
		@OfferId,
		@OrganizationId,
		@OrganizationName,
		@Subject,
		@Body,
		@SentDate,
		@RealizationDate,
		@Price,
		@OrganizationEmail,
		@ContactPersonEmail,
		@ResponsibleEmail,
		@OfferState
END

CLOSE cur
DEALLOCATE cur
GO
ALTER PROCEDURE [dbo].[SendOfferFillEForm]
AS

DECLARE @Today DATETIME = FLOOR(CAST(GETDATE() AS FLOAT))

DECLARE
	@OfferId INT,
	@OrganizationId INT,
	@OrganizationName VARCHAR(100),
	@Subject VARCHAR(255),
	@Body VARCHAR(MAX),
	@SentDate DATETIME,
	@RealizationDate DATETIME,
	@Price VARCHAR(32),
	@OrganizationEmail VARCHAR(100),
	@ContactPersonEmail VARCHAR(MAX),
	@ResponsibleEmail VARCHAR(100),
	@OfferState VARCHAR(50)
	
DECLARE cur CURSOR FAST_FORWARD FOR
SELECT
	offers.Id AS OfferId,
	offers.OrganizationId,
	ISNULL(organization.Nazov, 'Nezadané')  AS OrganizationName,
	ISNULL(offers.[Subject], 'Nezadané') AS [Subject],
	ISNULL(offers.Body, 'Nezadané') AS Body,
	offers.SentDate,
	offers.RealizationDate,
	ISNULL(CAST(offers.Price AS VARCHAR(32)) + ' €', 'Nezadané') AS Price,
	ISNULL(organization.Mail, 'Nezadané') AS OrganizationEmail,
	report.GetKontaktnaOsobaEmail(offers.OrganizationId) AS ContactPersonEmail,
	responsible.Email AS ResponsibleEmail,
	offerStates.Name AS OfferState
FROM
	dbo.Offers offers
	LEFT JOIN dbo.Organizacia organization
		ON organization.ID = offers.OrganizationId
	LEFT JOIN dbo.Zamestnanec responsible
		ON responsible.ID = offers.ResponsibleEmployeeId
	LEFT JOIN dbo.OfferStates offerStates
		ON offerStates.Id = offers.OfferStateId
WHERE
	(
		@Today = CAST(YEAR(offers.RealizationDate) AS VARCHAR(4)) + '-12-10'
		OR
		@Today = CAST(YEAR(offers.RealizationDate) + 1 AS VARCHAR(4)) + '-01-07'
	)

OPEN cur
FETCH NEXT FROM cur INTO
	@OfferId,
	@OrganizationId,
	@OrganizationName,
	@Subject,
	@Body,
	@SentDate,
	@RealizationDate,
	@Price,
	@OrganizationEmail,
	@ContactPersonEmail,
	@ResponsibleEmail,
	@OfferState

WHILE @@FETCH_STATUS = 0
BEGIN
	--SELECT
	--	@OfferId AS OfferId,
	--	@OrganizationId AS OrganizationId,
	--	@Subject AS Subject,
	--	@Body AS Body,
	--	@SentDate AS SentDate,
	--	@Price AS Price,
	--	@OrganizationEmail AS OrganizationEmail,
	--	@ContactPersonEmail AS ContactPersonEmail,
	--	@ResponsibleEmail AS ResponsibleEmail

	DECLARE @Contacts VARCHAR(MAX) = '
--------------------------------------------------------------------------------------------------
<br/>E-mail kontaktných osôb:<br/>
' + @ContactPersonEmail + '<br/>
<br/>Názov organizácie:<br/>
<b>' + @OrganizationName + '</b><br/>
<br/>E-mail organizácie:<br/>
' + @OrganizationEmail + '<br/>
--------------------------------------------------------------------------------------------------
<br/>
<br/>
'
	DECLARE @18MonthAfter DATETIME = DATEADD(MONTH, 18, @RealizationDate) 

	SET @Subject = @Subject + ' - Vyplnenie elektronickeho formulara'
	SET @Subject = REPLACE(@Subject, '${OfferId}', @OfferId)
	SET @Subject = REPLACE(@Subject, '${OrganizationName}', @OrganizationName)

	SET @Body = '<br/><b>Vyplnte niekto elektronicky formular, prosim Vas.'
	SET @Body += '<br/><b>Datum Realizacie:</b> ${RealizationDate}'
	SET @Body += '<br/><b>Ponuka Id:</b> ${OfferId}'
	SET @Body += '<br/><b>Organizacia:</b> ${OrganizationName}'
	SET @Body += '<br/><b>Stav:</b> ${OfferState}'


	SET @Body = REPLACE(@Body, '${OfferId}', @OfferId)
	SET @Body = REPLACE(@Body, '${Price}', @Price)

	IF @OrganizationName IS NOT NULL
		SET @Body = REPLACE(@Body, '${OrganizationName}', @OrganizationName)

	IF @RealizationDate IS NOT NULL
		SET @Body = REPLACE(@Body, '${RealizationDate}', @RealizationDate)

	IF @SentDate IS NOT NULL
		SET @Body = REPLACE(@Body, '${SentDate}', @SentDate)

	IF @18MonthAfter IS NOT NULL
		SET @Body = REPLACE(@Body, '${18MonthAfter}', @18MonthAfter)

	IF @OfferState IS NOT NULL
		SET @Body = REPLACE(@Body, '${OfferState}', @OfferState)

	SET @Body = dbo.GetHtmlBodyOpenTag() + @Contacts + @Body + dbo.GetHtmlBodyCloseTag()

	EXEC msdb.dbo.sp_send_dbmail
		@recipients = 'miroslav.hanzen@gmail.com;monika.hanzenova@gmail.com',
		--@blind_copy_recipients = 'matej.cizmarik@2ring.com',
		@subject = @Subject,
		@body = @Body,
		@body_format = 'HTML'

	FETCH NEXT FROM cur INTO
		@OfferId,
		@OrganizationId,
		@OrganizationName,
		@Subject,
		@Body,
		@SentDate,
		@RealizationDate,
		@Price,
		@OrganizationEmail,
		@ContactPersonEmail,
		@ResponsibleEmail,
		@OfferState
END

CLOSE cur
DEALLOCATE cur
GO
ALTER PROCEDURE [dbo].[SendOfferStateReminder]
AS

DECLARE @Today DATETIME = FLOOR(CAST(GETDATE() AS FLOAT))

DECLARE
	@OfferId INT,
	@OrganizationId INT,
	@OrganizationName VARCHAR(100),
	@Subject VARCHAR(255),
	@Body VARCHAR(MAX),
	@SentDate DATETIME,
	@RealizationDate DATETIME,
	@Price VARCHAR(32),
	@OrganizationEmail VARCHAR(100),
	@ContactPersonEmail VARCHAR(MAX),
	@ResponsibleEmail VARCHAR(100),
	@OfferState VARCHAR(50)
	
DECLARE cur CURSOR FAST_FORWARD FOR
SELECT
	offers.Id AS OfferId,
	offers.OrganizationId,
	organization.Nazov AS OrganizationName,
	ISNULL(offers.[Subject], 'Nezadané') AS [Subject],
	ISNULL(offers.Body, 'Nezadané') AS Body,
	offers.SentDate,
	offers.RealizationDate,
	ISNULL(CAST(offers.Price AS VARCHAR(32)) + ' €', 'Nezadané') AS Price,
	ISNULL(organization.Mail, 'Nezadané') AS OrganizationEmail,
	report.GetKontaktnaOsobaEmail(offers.OrganizationId) AS ContactPersonEmail,
	responsible.Email AS ResponsibleEmail,
	offerStates.Name AS OfferState
FROM
	dbo.Offers offers
	LEFT JOIN dbo.Organizacia organization
		ON organization.ID = offers.OrganizationId
	LEFT JOIN dbo.Zamestnanec responsible
		ON responsible.ID = offers.ResponsibleEmployeeId
	LEFT JOIN dbo.OfferStates offerStates
		ON offerStates.Id = offers.OfferStateId
WHERE
	DATEADD(DAY, 14, FLOOR(CAST(offers.RealizationDate AS FLOAT))) = @Today
	AND
	offers.OfferStateId = 1 --Odoslana

OPEN cur
FETCH NEXT FROM cur INTO
	@OfferId,
	@OrganizationId,
	@OrganizationName,
	@Subject,
	@Body,
	@SentDate,
	@RealizationDate,
	@Price,
	@OrganizationEmail,
	@ContactPersonEmail,
	@ResponsibleEmail,
	@OfferState

WHILE @@FETCH_STATUS = 0
BEGIN
	--SELECT
	--	@OfferId AS OfferId,
	--	@OrganizationId AS OrganizationId,
	--	@Subject AS Subject,
	--	@Body AS Body,
	--	@SentDate AS SentDate,
	--	@Price AS Price,
	--	@OrganizationEmail AS OrganizationEmail,
	--	@ContactPersonEmail AS ContactPersonEmail,
	--	@ResponsibleEmail AS ResponsibleEmail

	DECLARE @Contacts VARCHAR(MAX) = '
--------------------------------------------------------------------------------------------------
<br/>E-mail kontaktných osôb:<br/>
' + @ContactPersonEmail + '<br/>
<br/>Názov organizácie:<br/>
<b>' + @OrganizationName + '</b><br/>
<br/>E-mail organizácie:<br/>
' + @OrganizationEmail + '<br/>
--------------------------------------------------------------------------------------------------
<br/>
<br/>
'
	DECLARE @18MonthAfter DATETIME = DATEADD(MONTH, 18, @RealizationDate) 

	SET @Subject = @Subject + ' - Prebehlo 14 dni od odslania ponuky'
	SET @Subject = REPLACE(@Subject, '${OfferId}', @OfferId)
	SET @Subject = REPLACE(@Subject, '${OrganizationName}', @OrganizationName)

	SET @Body = '<br/><b>Ponuka ma stale stav odoslana.'
	SET @Body += '<br/><b>Datum odoslania:</b> ${SentDate}'
	SET @Body += '<br/><b>Ponuka Id:</b> ${OfferId}'
	SET @Body += '<br/><b>Organizacia:</b> ${OrganizationName}'
	SET @Body += '<br/><b>Stav:</b> ${OfferState}'

	SET @Body = REPLACE(@Body, '${OfferId}', @OfferId)
	SET @Body = REPLACE(@Body, '${Price}', @Price)

	IF @OrganizationName IS NOT NULL
		SET @Body = REPLACE(@Body, '${OrganizationName}', @OrganizationName)

	IF @RealizationDate IS NOT NULL
		SET @Body = REPLACE(@Body, '${RealizationDate}', @RealizationDate)

	IF @SentDate IS NOT NULL
		SET @Body = REPLACE(@Body, '${SentDate}', @SentDate)

	IF @18MonthAfter IS NOT NULL
		SET @Body = REPLACE(@Body, '${18MonthAfter}', @18MonthAfter)

	IF @OfferState IS NOT NULL
		SET @Body = REPLACE(@Body, '${OfferState}', @OfferState)

	SET @Body = dbo.GetHtmlBodyOpenTag() + @Contacts + @Body + dbo.GetHtmlBodyCloseTag()

	EXEC msdb.dbo.sp_send_dbmail
		@recipients = 'miroslav.hanzen@gmail.com;monika.hanzenova@gmail.com',
		--@blind_copy_recipients = 'matej.cizmarik@2ring.com',
		@subject = @Subject,
		@body = @Body,
		@body_format = 'HTML'

	FETCH NEXT FROM cur INTO
		@OfferId,
		@OrganizationId,
		@OrganizationName,
		@Subject,
		@Body,
		@SentDate,
		@RealizationDate,
		@Price,
		@OrganizationEmail,
		@ContactPersonEmail,
		@ResponsibleEmail,
		@OfferState
END

CLOSE cur
DEALLOCATE cur
GO
ALTER PROCEDURE [dbo].[SendOfferChangeToOrder]
AS

DECLARE
	@OfferId INT,
	@OrganizationId INT,
	@OrganizationName VARCHAR(100),
	@Subject VARCHAR(255),
	@Body VARCHAR(MAX),
	@SentDate DATETIME,
	@RealizationDate DATETIME,
	@Price VARCHAR(32),
	@OrganizationEmail VARCHAR(100),
	@ContactPersonEmail VARCHAR(MAX),
	@ResponsibleEmail VARCHAR(100),
	@OfferState VARCHAR(50),
	@OfferStateId INT
	
DECLARE cur CURSOR FAST_FORWARD FOR
SELECT
	offers.Id AS OfferId,
	offers.OrganizationId,
	ISNULL(organization.Nazov, 'Nezadané')  AS OrganizationName,
	ISNULL(offers.[Subject], 'Nezadané') AS [Subject],
	ISNULL(offers.Body, 'Nezadané') AS Body,
	offers.SentDate,
	offers.RealizationDate,
	ISNULL(CAST(offers.Price AS VARCHAR(32)) + ' €', 'Nezadané') AS Price,
	ISNULL(organization.Mail, 'Nezadané') AS OrganizationEmail,
	report.GetKontaktnaOsobaEmail(offers.OrganizationId) AS ContactPersonEmail,
	responsible.Email AS ResponsibleEmail,
	offerStates.Name AS OfferState,
	offers.OfferStateId
FROM
	dbo.Offers offers
	LEFT JOIN dbo.OffersSent offersSent
		ON offersSent.OfferId = offers.Id
	LEFT JOIN dbo.Organizacia organization
		ON organization.ID = offers.OrganizationId
	LEFT JOIN dbo.Zamestnanec responsible
		ON responsible.ID = offers.ResponsibleEmployeeId
	LEFT JOIN dbo.OfferStates offerStates
		ON offerStates.Id = offers.OfferStateId
WHERE
	offers.OfferStateId = 2 --Objednana
	AND
	(
		offersSent.OfferStateId IS NULL
		OR
		offersSent.OfferStateId != 2
	)

OPEN cur
FETCH NEXT FROM cur INTO
	@OfferId,
	@OrganizationId,
	@OrganizationName,
	@Subject,
	@Body,
	@SentDate,
	@RealizationDate,
	@Price,
	@OrganizationEmail,
	@ContactPersonEmail,
	@ResponsibleEmail,
	@OfferState,
	@OfferStateId

WHILE @@FETCH_STATUS = 0
BEGIN
	--SELECT
	--	@OfferId AS OfferId,
	--	@OrganizationId AS OrganizationId,
	--	@Subject AS Subject,
	--	@Body AS Body,
	--	@SentDate AS SentDate,
	--	@RealizationDate AS RealizationDate,
	--	@Price AS Price,
	--	@OrganizationEmail AS OrganizationEmail,
	--	@ContactPersonEmail AS ContactPersonEmail,
	--	@ResponsibleEmail AS ResponsibleEmail,
	--	@OfferState AS OfferState,
	--	@OfferStateId AS OfferStateId

	DECLARE @Contacts VARCHAR(MAX) = '
--------------------------------------------------------------------------------------------------
<br/>E-mail kontaktných osôb:<br/>
' + @ContactPersonEmail + '<br/>
<br/>Názov organizácie:<br/>
<b>' + @OrganizationName + '</b><br/>
<br/>E-mail organizácie:<br/>
' + @OrganizationEmail + '<br/>
--------------------------------------------------------------------------------------------------
<br/>
<br/>
'
	DECLARE @18MonthAfter DATETIME = DATEADD(MONTH, 18, @RealizationDate) 

	SET @Subject = @Subject + ' - ${OfferState}'
	SET @Subject = REPLACE(@Subject, '${OfferId}', @OfferId)
	SET @Subject = REPLACE(@Subject, '${OrganizationName}', @OrganizationName)
	SET @Subject = REPLACE(@Subject, '${OfferState}', @OfferState)

	SET @Body = '<br/>Ponuke sa zmenil stav na objednana.<br/>'
	SET @Body += '<br/><b>Datum odoslania:</b> ${SentDate}'
	SET @Body += '<br/><b>Ponuka Id:</b> ${OfferId}'
	SET @Body += '<br/><b>Organizacia:</b> ${OrganizationName}'
	SET @Body += '<br/><b>Stav:</b> ${OfferState}'

	SET @Body = REPLACE(@Body, '${OfferId}', @OfferId)

	--SET @Body = REPLACE(@Body, '${Price}', @Price)

	IF @OrganizationName IS NOT NULL
		SET @Body = REPLACE(@Body, '${OrganizationName}', @OrganizationName)

	IF @RealizationDate IS NOT NULL
		SET @Body = REPLACE(@Body, '${RealizationDate}', @RealizationDate)

	IF @SentDate IS NOT NULL
		SET @Body = REPLACE(@Body, '${SentDate}', @SentDate)

	IF @18MonthAfter IS NOT NULL
		SET @Body = REPLACE(@Body, '${18MonthAfter}', @18MonthAfter)

	IF @OfferState IS NOT NULL
		SET @Body = REPLACE(@Body, '${OfferState}', @OfferState)

	SET @Body = dbo.GetHtmlBodyOpenTag() + @Contacts + @Body + dbo.GetHtmlBodyCloseTag()
	--PRINT @Body

	SET @ResponsibleEmail = ISNULL(@ResponsibleEmail + '; ', '');
	SET @ResponsibleEmail += 'izabela.jagerova@skolboz.sk';

	EXEC msdb.dbo.sp_send_dbmail
		@recipients = @ResponsibleEmail,
		@copy_recipients = 'miroslav.hanzen@gmail.com;monika.hanzenova@gmail.com',
		--@blind_copy_recipients = 'matej.cizmarik@2ring.com',
		@subject = @Subject,
		@body = @Body,
		@body_format = 'HTML'

	EXEC [dbo].[OffersSentUpdate] @OfferId, @SentDate, @OfferStateId

	FETCH NEXT FROM cur INTO
		@OfferId,
		@OrganizationId,
		@OrganizationName,
		@Subject,
		@Body,
		@SentDate,
		@RealizationDate,
		@Price,
		@OrganizationEmail,
		@ContactPersonEmail,
		@ResponsibleEmail,
		@OfferState,
		@OfferStateId
END

CLOSE cur
DEALLOCATE cur
GO
ALTER PROCEDURE [dbo].[SendOfferChangeToRealization]
AS

DECLARE
	@OfferId INT,
	@OrganizationId INT,
	@OrganizationName VARCHAR(100),
	@Subject VARCHAR(255),
	@Body VARCHAR(MAX),
	@SentDate DATETIME,
	@RealizationDate DATETIME,
	@Price VARCHAR(32),
	@OrganizationEmail VARCHAR(100),
	@ContactPersonEmail VARCHAR(MAX),
	@ResponsibleEmail VARCHAR(100),
	@OfferState VARCHAR(50),
	@OfferStateId INT
	
DECLARE cur CURSOR FAST_FORWARD FOR
SELECT
	offers.Id AS OfferId,
	offers.OrganizationId,
	ISNULL(organization.Nazov, 'Nezadané')  AS OrganizationName,
	ISNULL(offers.[Subject], 'Nezadané') AS [Subject],
	ISNULL(offers.Body, 'Nezadané') AS Body,
	offers.SentDate,
	offers.RealizationDate,
	ISNULL(CAST(offers.Price AS VARCHAR(32)) + ' €', 'Nezadané') AS Price,
	ISNULL(organization.Mail, 'Nezadané') AS OrganizationEmail,
	report.GetKontaktnaOsobaEmail(offers.OrganizationId) AS ContactPersonEmail,
	responsible.Email AS ResponsibleEmail,
	offerStates.Name AS OfferState,
	offers.OfferStateId
FROM
	dbo.Offers offers
	LEFT JOIN dbo.OffersSent offersSent
		ON offersSent.OfferId = offers.Id
	LEFT JOIN dbo.Organizacia organization
		ON organization.ID = offers.OrganizationId
	LEFT JOIN dbo.Zamestnanec responsible
		ON responsible.ID = offers.ResponsibleEmployeeId
	LEFT JOIN dbo.OfferStates offerStates
		ON offerStates.Id = offers.OfferStateId
WHERE
	offers.OfferStateId = 3 --Ukoncena/Realizovana
	AND
	(
		offersSent.OfferStateId IS NULL
		OR
		offersSent.OfferStateId != 3
	)

OPEN cur
FETCH NEXT FROM cur INTO
	@OfferId,
	@OrganizationId,
	@OrganizationName,
	@Subject,
	@Body,
	@SentDate,
	@RealizationDate,
	@Price,
	@OrganizationEmail,
	@ContactPersonEmail,
	@ResponsibleEmail,
	@OfferState,
	@OfferStateId

WHILE @@FETCH_STATUS = 0
BEGIN
	--SELECT
	--	@OfferId AS OfferId,
	--	@OrganizationId AS OrganizationId,
	--	@Subject AS Subject,
	--	@Body AS Body,
	--	@SentDate AS SentDate,
	--	@Price AS Price,
	--	@OrganizationEmail AS OrganizationEmail,
	--	@ContactPersonEmail AS ContactPersonEmail,
	--	@ResponsibleEmail AS ResponsibleEmail

	DECLARE @Contacts VARCHAR(MAX) = '
--------------------------------------------------------------------------------------------------
<br/>E-mail kontaktných osôb:<br/>
' + @ContactPersonEmail + '<br/>
<br/>Názov organizácie:<br/>
<b>' + @OrganizationName + '</b><br/>
<br/>E-mail organizácie:<br/>
' + @OrganizationEmail + '<br/>
--------------------------------------------------------------------------------------------------
<br/>
<br/>
'
	DECLARE @18MonthAfter DATETIME = DATEADD(MONTH, 18, @RealizationDate) 

	SET @Subject = @Subject + ' - ${OfferState}'
	SET @Subject = REPLACE(@Subject, '${OfferId}', @OfferId)
	SET @Subject = REPLACE(@Subject, '${OrganizationName}', @OrganizationName)
	SET @Subject = REPLACE(@Subject, '${OfferState}', @OfferState)

	SET @Body = '<br/>Ponuke sa zmenil stav na ukoncena/realizovana.<br/>'
	SET @Body += '<br/><b>Datum odoslania:</b> ${SentDate}'
	SET @Body += '<br/><b>Datum odoslania:</b> ${RealizationDate}'
	SET @Body += '<br/><b>Ponuka Id:</b> ${OfferId}'
	SET @Body += '<br/><b>Organizacia:</b> ${OrganizationName}'
	SET @Body += '<br/><b>Stav:</b> ${OfferState}'
	SET @Body += '<br/><b>Cena:</b> ${Price}'

	SET @Body = REPLACE(@Body, '${OfferId}', @OfferId)
	SET @Body = REPLACE(@Body, '${Price}', @Price)

	IF @OrganizationName IS NOT NULL
		SET @Body = REPLACE(@Body, '${OrganizationName}', @OrganizationName)

	IF @RealizationDate IS NOT NULL
		SET @Body = REPLACE(@Body, '${RealizationDate}', @RealizationDate)

	IF @SentDate IS NOT NULL
		SET @Body = REPLACE(@Body, '${SentDate}', @SentDate)

	IF @18MonthAfter IS NOT NULL
		SET @Body = REPLACE(@Body, '${18MonthAfter}', @18MonthAfter)

	IF @OfferState IS NOT NULL
		SET @Body = REPLACE(@Body, '${OfferState}', @OfferState)

	SET @Body = dbo.GetHtmlBodyOpenTag() + @Contacts + @Body + dbo.GetHtmlBodyCloseTag()

	EXEC msdb.dbo.sp_send_dbmail
		@recipients = 'monika.hanzenova@gmail.com',
		@copy_recipients = 'miroslav.hanzen@gmail.com',
		--@blind_copy_recipients = 'matej.cizmarik@2ring.com',
		@subject = @Subject,
		@body = @Body,
		@body_format = 'HTML'

	EXEC [dbo].[OffersSentUpdate] @OfferId, @SentDate, @OfferStateId

	FETCH NEXT FROM cur INTO
		@OfferId,
		@OrganizationId,
		@OrganizationName,
		@Subject,
		@Body,
		@SentDate,
		@RealizationDate,
		@Price,
		@OrganizationEmail,
		@ContactPersonEmail,
		@ResponsibleEmail,
		@OfferState,
		@OfferStateId
END

CLOSE cur
DEALLOCATE cur
GO
ALTER PROCEDURE [dbo].[SendOfferChangeSentDate]
AS
DECLARE
	@OfferId INT,
	@OrganizationId INT,
	@OfferStateId INT,
	@OrganizationName VARCHAR(100),
	@Subject VARCHAR(255),
	@Body VARCHAR(MAX),
	@SentDate DATETIME,
	@Price VARCHAR(32),
	@OrganizationEmail VARCHAR(100),
	@ContactPersonEmail VARCHAR(MAX),
	@ResponsibleEmail VARCHAR(100)
	
DECLARE cur CURSOR FAST_FORWARD FOR
SELECT
	offers.Id AS OfferId,
	offers.OrganizationId,
	offers.OfferStateId,
	ISNULL(organization.Nazov, 'Nezadané')  AS OrganizationName,
	ISNULL(offers.[Subject], 'Nezadané') AS [Subject],
	ISNULL(offers.Body, 'Nezadané') AS Body,
	offers.SentDate,
	ISNULL(CAST(offers.Price AS VARCHAR(32)) + ' €', 'Nezadané') AS Price,
	ISNULL(organization.Mail, 'Nezadané') AS OrganizationEmail,
	report.GetKontaktnaOsobaEmail(offers.OrganizationId) AS ContactPersonEmail,
	responsible.Email AS ResponsibleEmail
FROM
	dbo.Offers offers
	LEFT JOIN dbo.OffersSent offersSent
		ON offersSent.OfferId = offers.Id
	LEFT JOIN dbo.Organizacia organization
		ON organization.ID = offers.OrganizationId
	LEFT JOIN dbo.Zamestnanec responsible
		ON responsible.ID = offers.ResponsibleEmployeeId
WHERE
	offersSent.SentDate != offers.SentDate
	OR
	offersSent.SentDate IS NULL

OPEN cur
FETCH NEXT FROM cur INTO
	@OfferId,
	@OrganizationId,
	@OfferStateId,
	@OrganizationName,
	@Subject,
	@Body,
	@SentDate,
	@Price,
	@OrganizationEmail,
	@ContactPersonEmail,
	@ResponsibleEmail

WHILE @@FETCH_STATUS = 0
BEGIN
	--SELECT
	--	@OfferId AS OfferId,
	--	@OrganizationId AS OrganizationId,
	--	@Subject AS Subject,
	--	@Body AS Body,
	--	@SentDate AS SentDate,
	--	@Price AS Price,
	--	@OrganizationEmail AS OrganizationEmail,
	--	@ContactPersonEmail AS ContactPersonEmail,
	--	@ResponsibleEmail AS ResponsibleEmail

	DECLARE @Contacts VARCHAR(MAX) = '
--------------------------------------------------------------------------------------------------
<br/>E-mail kontaktných osôb:<br/>
' + @ContactPersonEmail + '<br/>
<br/>Názov organizácie:<br/>
<b>' + @OrganizationName + '</b><br/>
<br/>E-mail organizácie:<br/>
' + @OrganizationEmail + '<br/>
--------------------------------------------------------------------------------------------------
<br/>
<br/>
'
	SET @Subject = REPLACE(@Subject, '${OfferId}', @OfferId)
	SET @Subject = REPLACE(@Subject, '${Price}', @Price)
	SET @Subject = REPLACE(@Subject, '${OrganizationName}', @OrganizationName)

	DECLARE @AdminBody VARCHAR(MAX) = REPLACE(@Body, '${Price}', @Price)
	SET @AdminBody = REPLACE(@AdminBody, '${OfferId}', @OfferId)
	SET @AdminBody = REPLACE(@AdminBody, char(13), '<br/>' + char(13))
	SET @AdminBody = dbo.GetHtmlBodyOpenTag() + @Contacts + @AdminBody + dbo.GetHtmlBodyCloseTag()
	--PRINT @AdminBody

	EXEC msdb.dbo.sp_send_dbmail
		@recipients = 'miroslav.hanzen@gmail.com;monika.hanzenova@gmail.com',
		--@blind_copy_recipients = 'matej.cizmarik@2ring.com',
		@subject = @Subject,
		@body = @AdminBody,
		@body_format = 'HTML'

	EXEC [dbo].[OffersSentUpdate] @OfferId, @SentDate, @OfferStateId

	FETCH NEXT FROM cur INTO
		@OfferId,
		@OrganizationId,
		@OfferStateId,
		@OrganizationName,
		@Subject,
		@Body,
		@SentDate,
		@Price,
		@OrganizationEmail,
		@ContactPersonEmail,
		@ResponsibleEmail
END

CLOSE cur
DEALLOCATE cur
GO