USE [master]
GO
CREATE LOGIN [SpravaZmluvUser] WITH PASSWORD=N'SpravaZmluvUser', DEFAULT_DATABASE=SpravaZmluv, CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
USE SpravaZmluv
EXEC sp_change_users_login 'update_one', 'SpravaZmluvUser', 'SpravaZmluvUser'
GO
GRANT CONNECT TO SpravaZmluvUser
GO
