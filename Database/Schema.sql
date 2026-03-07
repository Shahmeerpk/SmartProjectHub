-- =============================================
-- Smart Academic Project Hub - SQL Server Schema
-- Production-ready with hashed passwords, JWT-ready
-- =============================================

USE master;
GO
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'SmartAcademicProjectHub')
    CREATE DATABASE SmartAcademicProjectHub;
GO
USE SmartAcademicProjectHub;
GO

-- Drop tables in reverse dependency order (so FKs don't block)
IF OBJECT_ID(N'dbo.ChatChannelMembers', N'U') IS NOT NULL DROP TABLE dbo.ChatChannelMembers;
IF OBJECT_ID(N'dbo.ChatMessages', N'U') IS NOT NULL DROP TABLE dbo.ChatMessages;
IF OBJECT_ID(N'dbo.ChatChannels', N'U') IS NOT NULL DROP TABLE dbo.ChatChannels;
IF OBJECT_ID(N'dbo.Projects', N'U') IS NOT NULL DROP TABLE dbo.Projects;
IF OBJECT_ID(N'dbo.RefreshTokens', N'U') IS NOT NULL DROP TABLE dbo.RefreshTokens;
IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL DROP TABLE dbo.Users;
IF OBJECT_ID(N'dbo.Universities', N'U') IS NOT NULL DROP TABLE dbo.Universities;
GO

-- =============================================
-- Universities
-- =============================================
CREATE TABLE dbo.Universities (
    Id              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name            NVARCHAR(200) NOT NULL,
    Code            NVARCHAR(50) NOT NULL UNIQUE,
    CreatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    IsActive        BIT NOT NULL DEFAULT 1
);
GO

-- =============================================
-- Users (Students & Teachers) - password hashed server-side
-- =============================================
CREATE TABLE dbo.Users (
    Id              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Email           NVARCHAR(256) NOT NULL UNIQUE,
    PasswordHash    NVARCHAR(256) NOT NULL,
    PasswordSalt    NVARCHAR(128) NOT NULL,
    FullName        NVARCHAR(200) NOT NULL,
    Role            NVARCHAR(20) NOT NULL CHECK (Role IN (N'Student', N'Teacher')),
    UniversityId    INT NOT NULL,
    IsActive        BIT NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    LastLoginAt     DATETIME2(0) NULL,
    CONSTRAINT FK_Users_Universities FOREIGN KEY (UniversityId) REFERENCES dbo.Universities(Id)
);
GO
CREATE INDEX IX_Users_Email ON dbo.Users(Email);
CREATE INDEX IX_Users_UniversityId ON dbo.Users(UniversityId);
CREATE INDEX IX_Users_Role ON dbo.Users(Role);
GO

-- =============================================
-- Refresh Tokens (for JWT logout / session invalidation)
-- =============================================
CREATE TABLE dbo.RefreshTokens (
    Id              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    UserId          INT NOT NULL,
    Token           NVARCHAR(512) NOT NULL,
    ExpiresAt       DATETIME2(0) NOT NULL,
    CreatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    RevokedAt       DATETIME2(0) NULL,
    CONSTRAINT FK_RefreshTokens_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE
);
GO
CREATE INDEX IX_RefreshTokens_UserId ON dbo.RefreshTokens(UserId);
CREATE INDEX IX_RefreshTokens_Token ON dbo.RefreshTokens(Token);
GO

-- =============================================
-- Projects (Title, Abstract, Status, Progress, 3D model path)
-- =============================================
CREATE TABLE dbo.Projects (
    Id                  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Title               NVARCHAR(500) NOT NULL,
    Abstract            NVARCHAR(MAX) NOT NULL,
    StudentId           INT NOT NULL,
    TeacherId           INT NULL,
    UniversityId        INT NOT NULL,
    Status              NVARCHAR(30) NOT NULL DEFAULT N'Pending'
        CHECK (Status IN (N'Pending', N'Approved', N'Rejected')),
    ProgressPercent     DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (ProgressPercent >= 0 AND ProgressPercent <= 100),
    SimilarityScore     DECIMAL(5,2) NULL,
    RejectionReason     NVARCHAR(500) NULL,
    ObjModelUrl         NVARCHAR(1000) NULL,
    ReviewedAt          DATETIME2(0) NULL,
    CreatedAt           DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Projects_Student FOREIGN KEY (StudentId) REFERENCES dbo.Users(Id),
    CONSTRAINT FK_Projects_Teacher FOREIGN KEY (TeacherId) REFERENCES dbo.Users(Id),
    CONSTRAINT FK_Projects_University FOREIGN KEY (UniversityId) REFERENCES dbo.Universities(Id)
);
GO
CREATE INDEX IX_Projects_StudentId ON dbo.Projects(StudentId);
CREATE INDEX IX_Projects_TeacherId ON dbo.Projects(TeacherId);
CREATE INDEX IX_Projects_UniversityId ON dbo.Projects(UniversityId);
CREATE INDEX IX_Projects_Status ON dbo.Projects(Status);
GO

-- =============================================
-- Chat: Channels (Private/Project, University, Global)
-- =============================================
CREATE TABLE dbo.ChatChannels (
    Id              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name            NVARCHAR(200) NOT NULL,
    ChannelType     NVARCHAR(20) NOT NULL CHECK (ChannelType IN (N'Private', N'University', N'Global')),
    ProjectId       INT NULL,
    UniversityId    INT NULL,
    CreatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_ChatChannels_Project FOREIGN KEY (ProjectId) REFERENCES dbo.Projects(Id) ON DELETE CASCADE,
    CONSTRAINT FK_ChatChannels_University FOREIGN KEY (UniversityId) REFERENCES dbo.Universities(Id)
);
GO
CREATE INDEX IX_ChatChannels_ProjectId ON dbo.ChatChannels(ProjectId);
CREATE INDEX IX_ChatChannels_UniversityId ON dbo.ChatChannels(UniversityId);
CREATE INDEX IX_ChatChannels_ChannelType ON dbo.ChatChannels(ChannelType);
GO

-- =============================================
-- Chat: Messages
-- =============================================
CREATE TABLE dbo.ChatMessages (
    Id              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ChannelId       INT NOT NULL,
    UserId          INT NOT NULL,
    Content         NVARCHAR(MAX) NOT NULL,
    CreatedAt       DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_ChatMessages_Channel FOREIGN KEY (ChannelId) REFERENCES dbo.ChatChannels(Id) ON DELETE CASCADE,
    CONSTRAINT FK_ChatMessages_User FOREIGN KEY (UserId) REFERENCES dbo.Users(Id)
);
GO
CREATE INDEX IX_ChatMessages_ChannelId ON dbo.ChatMessages(ChannelId);
CREATE INDEX IX_ChatMessages_UserId ON dbo.ChatMessages(UserId);
CREATE INDEX IX_ChatMessages_CreatedAt ON dbo.ChatMessages(CreatedAt);
GO

-- =============================================
-- Channel Members (who can access which channel)
-- =============================================
CREATE TABLE dbo.ChatChannelMembers (
    Id              INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ChannelId       INT NOT NULL,
    UserId          INT NOT NULL,
    JoinedAt        DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_ChannelMember UNIQUE (ChannelId, UserId),
    CONSTRAINT FK_ChannelMembers_Channel FOREIGN KEY (ChannelId) REFERENCES dbo.ChatChannels(Id) ON DELETE CASCADE,
    CONSTRAINT FK_ChannelMembers_User FOREIGN KEY (UserId) REFERENCES dbo.Users(Id) ON DELETE CASCADE
);
GO
CREATE INDEX IX_ChatChannelMembers_UserId ON dbo.ChatChannelMembers(UserId);
GO

-- =============================================
-- Seed: Sample University & Test Users (passwords hashed in API)
-- =============================================
INSERT INTO dbo.Universities (Name, Code) VALUES
    (N'Demo University', N'DEMO'),
    (N'Tech Institute', N'TECH');
GO

-- Note: Insert users and set PasswordHash/PasswordSalt via API (e.g. Register endpoint)
-- Example placeholder hashes (BCrypt-style); replace with real hashes from your API.
-- INSERT INTO dbo.Users (Email, PasswordHash, PasswordSalt, FullName, Role, UniversityId)
-- VALUES (N'student@demo.edu', N'<hash>', N'<salt>', N'Test Student', N'Student', 1);

PRINT 'Schema created successfully.';
GO
