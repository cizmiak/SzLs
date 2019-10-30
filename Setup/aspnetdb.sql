--USE aspnetdb
--EXEC sp_change_users_login 'update_one', 'SpravaZmluvUser', 'SpravaZmluvUser'
--GO
USE [aspnetdb]
GO

CREATE TABLE [dbo].[RolePermissions](
	[RoleName] [nvarchar](128) NOT NULL,
	[PermissionId] [nvarchar](256) NOT NULL,
 CONSTRAINT [PK_RolePermissions] PRIMARY KEY CLUSTERED 
(
	[RoleName] ASC,
	[PermissionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[RolePermissions] ADD  CONSTRAINT [DF_RolePermissions_RoleName]  DEFAULT ('') FOR [RoleName]
GO

ALTER TABLE [dbo].[RolePermissions] ADD  CONSTRAINT [DF_RolePermissions_PermissionId]  DEFAULT ('') FOR [PermissionId]
GO

INSERT dbo.RolePermissions (RoleName, PermissionId)
VALUES ('Administrator', 'Microsoft.LightSwitch.Security:SecurityAdministration')
GO

CREATE USER [SpravaZmluvUser] FOR LOGIN [SpravaZmluvUser]
GO
GRANT CONNECT TO SpravaZmluvUser
GO
GRANT EXEC TO SpravaZmluvUser
GO
GRANT SELECT TO SpravaZmluvUser
GO