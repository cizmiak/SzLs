USE [SpravaZmluv]
GO
/****** Object:  Table [dbo].[EmailTemplate]    Script Date: 18.02.2019 22:44:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmailTemplate](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](100) NULL,
	[Subject] [varchar](255) NULL,
	[Body] [varchar](max) NULL,
 CONSTRAINT [PK_EmailTemplate] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Offers]    Script Date: 18.02.2019 22:44:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Offers](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[OrganizationId] [int] NULL,
	[EmailTemplateId] [int] NULL,
	[Subject] [varchar](255) NULL,
	[Body] [varchar](max) NULL,
	[OfferStateId] [int] NULL,
	[SentDate] [datetime] NULL,
	[RealizationDate] [datetime] NULL,
	[ResponsibleEmployeeId] [int] NULL,
	[Price] [money] NULL,
	[IdInt]  AS ([Id]),
	[IdVarchar]  AS (CONVERT([varchar](10),[Id],0)),
	[OrganizationName]  AS ([dbo].[GetOrganizaciaNazov]([OrganizationId])),
 CONSTRAINT [PK_Offers] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[OffersSent]    Script Date: 18.02.2019 22:44:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OffersSent](
	[OfferId] [int] NOT NULL,
	[SentDate] [datetime] NULL,
 CONSTRAINT [PK_OffersSent] PRIMARY KEY CLUSTERED 
(
	[OfferId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[OfferStates]    Script Date: 18.02.2019 22:44:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OfferStates](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NULL,
 CONSTRAINT [PK_OfferStates] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Offers]  WITH CHECK ADD  CONSTRAINT [FK_Offers_EmailTemplate] FOREIGN KEY([EmailTemplateId])
REFERENCES [dbo].[EmailTemplate] ([Id])
GO
ALTER TABLE [dbo].[Offers] CHECK CONSTRAINT [FK_Offers_EmailTemplate]
GO
ALTER TABLE [dbo].[Offers]  WITH CHECK ADD  CONSTRAINT [FK_Offers_OfferStates] FOREIGN KEY([OfferStateId])
REFERENCES [dbo].[OfferStates] ([Id])
GO
ALTER TABLE [dbo].[Offers] CHECK CONSTRAINT [FK_Offers_OfferStates]
GO
ALTER TABLE [dbo].[Offers]  WITH CHECK ADD  CONSTRAINT [FK_Offers_Organization] FOREIGN KEY([OrganizationId])
REFERENCES [dbo].[Organizacia] ([ID])
GO
ALTER TABLE [dbo].[Offers] CHECK CONSTRAINT [FK_Offers_Organization]
GO
ALTER TABLE [dbo].[Offers]  WITH CHECK ADD  CONSTRAINT [FK_Offers_ResponsibleEmployee] FOREIGN KEY([ResponsibleEmployeeId])
REFERENCES [dbo].[Zamestnanec] ([ID])
GO
ALTER TABLE [dbo].[Offers] CHECK CONSTRAINT [FK_Offers_ResponsibleEmployee]
GO
ALTER TABLE [dbo].[OffersSent]  WITH CHECK ADD  CONSTRAINT [FK_OffersSent_Offers] FOREIGN KEY([OfferId])
REFERENCES [dbo].[Offers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[OffersSent] CHECK CONSTRAINT [FK_OffersSent_Offers]
GO
/****** Object:  StoredProcedure [dbo].[OffersSentUpdate]    Script Date: 18.02.2019 22:44:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[OffersSentUpdate]
	@OfferId INT,
	@SentDate DATETIME = NULL
AS
UPDATE dbo.OffersSent
SET SentDate = ISNULL(@SentDate, GETDATE())
WHERE OfferId = @OfferId

IF @@ROWCOUNT = 0
	INSERT dbo.OffersSent(OfferId, SentDate)
	VALUES (@OfferId, ISNULL(@SentDate, GETDATE()))
GO
/****** Object:  StoredProcedure [dbo].[SendOfferEmail]    Script Date: 18.02.2019 22:44:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SendOfferEmail]
AS
DECLARE
	@OfferId INT,
	@OrganizationId INT,
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
<br/>E-mail organizácie:<br/>
' + @OrganizationEmail + '<br/>
--------------------------------------------------------------------------------------------------
<br/>
<br/>
'
	SET @Subject = REPLACE(@Subject, '${OfferId}', @OfferId)

	DECLARE @AdminBody VARCHAR(MAX) = REPLACE(@Body, '${Price}', @Price)
	SET @AdminBody = REPLACE(@AdminBody, '${OfferId}', @OfferId)
	SET @AdminBody = dbo.GetHtmlBodyOpenTag() + @Contacts + @AdminBody + dbo.GetHtmlBodyCloseTag()
	--PRINT @AdminBody

	EXEC msdb.dbo.sp_send_dbmail
		@recipients = 'miroslav.hanzen@gmail.com;monika.hanzenova@gmail.com',
		@blind_copy_recipients = 'matej.cizmarik@2ring.com',
		@subject = @Subject,
		@body = @AdminBody,
		@body_format = 'HTML'
	
	--IF @ResponsibleEmail IS NOT NULL
	--BEGIN
	--	DECLARE @ResponsibleBody VARCHAR(MAX) = REPLACE(@Body, '${Price}', '-')
	--	SET @ResponsibleBody = REPLACE(@ResponsibleBody, '${OfferId}', @OfferId)
	--	SET @ResponsibleBody = dbo.GetHtmlBodyOpenTag() + @Contacts + @ResponsibleBody + dbo.GetHtmlBodyCloseTag()
	--	--PRINT @ResponsibleBody

	--	EXEC msdb.dbo.sp_send_dbmail
	--		@recipients = @ResponsibleEmail,
	--		@subject = @Subject,
	--		@body = @ResponsibleBody,
	--		@body_format = 'HTML'
	--END

	EXEC [dbo].[OffersSentUpdate] @OfferId, @SentDate

	FETCH NEXT FROM cur INTO
		@OfferId,
		@OrganizationId,
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
