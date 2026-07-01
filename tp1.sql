---------------------------------------------------
-- 0. CREAR BASE (si no existe) Y USARLA
----------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'PracticeJoinSubqueries')
BEGIN
    CREATE DATABASE PracticeJoinSubqueries;
END
GO

USE PracticeJoinSubqueries;
GO

----------------------------------------------------
-- 1. ELIMINAR FOREIGN KEYS SI EXISTEN
----------------------------------------------------
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Employees_Departments')
    ALTER TABLE dbo.Employees DROP CONSTRAINT FK_Employees_Departments;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Projects_Employees')
    ALTER TABLE dbo.Projects DROP CONSTRAINT FK_Projects_Employees;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Evaluations_Employees')
    ALTER TABLE dbo.Evaluations DROP CONSTRAINT FK_Evaluations_Employees;

----------------------------------------------------
-- 2. ELIMINAR ÍNDICES SI EXISTEN
----------------------------------------------------
IF EXISTS (SELECT name FROM sys.indexes WHERE name = 'IX_Employees_DepartmentID')
    DROP INDEX IX_Employees_DepartmentID ON dbo.Employees;

IF EXISTS (SELECT name FROM sys.indexes WHERE name = 'IX_Projects_LeaderEmployeeID')
    DROP INDEX IX_Projects_LeaderEmployeeID ON dbo.Projects;

IF EXISTS (SELECT name FROM sys.indexes WHERE name = 'IX_Evaluations_EmployeeID')
    DROP INDEX IX_Evaluations_EmployeeID ON dbo.Evaluations;

----------------------------------------------------
-- 3. ELIMINAR TABLAS SI EXISTEN
----------------------------------------------------
IF OBJECT_ID('dbo.Evaluations', 'U') IS NOT NULL DROP TABLE dbo.Evaluations;
IF OBJECT_ID('dbo.Projects', 'U') IS NOT NULL DROP TABLE dbo.Projects;
IF OBJECT_ID('dbo.Employees', 'U') IS NOT NULL DROP TABLE dbo.Employees;
IF OBJECT_ID('dbo.Departments', 'U') IS NOT NULL DROP TABLE dbo.Departments;
GO

----------------------------------------------------
-- 4. CREACIÓN DE TABLAS
----------------------------------------------------
CREATE TABLE dbo.Departments (
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    DepartmentName NVARCHAR(100) NOT NULL,
    Location NVARCHAR(100)
);
GO

CREATE TABLE dbo.Employees (
    EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(200) NOT NULL,
    HireDate DATE NOT NULL,
    Salary INT NOT NULL,
    DepartmentID INT NULL
);
GO

CREATE TABLE dbo.Projects (
    ProjectID INT IDENTITY(1,1) PRIMARY KEY,
    ProjectName NVARCHAR(150) NOT NULL,
    StartDate DATE NULL,
    EndDate DATE NULL,
    LeaderEmployeeID INT NULL
);
GO

CREATE TABLE dbo.Evaluations (
    EvalID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    EvalDate DATE NOT NULL,
    Score TINYINT NOT NULL CHECK (Score BETWEEN 1 AND 5),
    Comments NVARCHAR(400)
);
GO

----------------------------------------------------
-- 5. FOREIGN KEYS
----------------------------------------------------
ALTER TABLE dbo.Employees 
ADD CONSTRAINT FK_Employees_Departments 
FOREIGN KEY (DepartmentID) REFERENCES dbo.Departments(DepartmentID);

ALTER TABLE dbo.Projects 
ADD CONSTRAINT FK_Projects_Employees 
FOREIGN KEY (LeaderEmployeeID) REFERENCES dbo.Employees(EmployeeID);

ALTER TABLE dbo.Evaluations 
ADD CONSTRAINT FK_Evaluations_Employees 
FOREIGN KEY (EmployeeID) REFERENCES dbo.Employees(EmployeeID);
GO

----------------------------------------------------
-- 6. ÍNDICES
----------------------------------------------------
CREATE INDEX IX_Employees_DepartmentID ON dbo.Employees(DepartmentID);
CREATE INDEX IX_Projects_LeaderEmployeeID ON dbo.Projects(LeaderEmployeeID);
CREATE INDEX IX_Evaluations_EmployeeID ON dbo.Evaluations(EmployeeID);
GO

----------------------------------------------------
-- 7. INSERTAR DATOS
----------------------------------------------------

---------------------------
-- DEPARTAMENTOS
---------------------------
INSERT INTO dbo.Departments (DepartmentName, Location)
VALUES
('Recursos Humanos','Buenos Aires'),
('Desarrollo','CABA'),
('Ventas','Rosario'),
('Marketing','CABA'),
('Soporte','Mendoza'),
('Finanzas','Buenos Aires'),
('Operaciones','Córdoba'),
('Investigación','La Plata');
GO

---------------------------
-- 100 EMPLEADOS
---------------------------
;WITH tally AS (
    SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT INTO dbo.Employees (FirstName, LastName, Email, HireDate, Salary, DepartmentID)
SELECT
    'Emp' + RIGHT('000' + CAST(n AS VARCHAR(3)),3),
    'Apellido' + CAST(n AS VARCHAR(3)),
    'emp' + CAST(n AS VARCHAR(3)) + '@example.com',
    DATEADD(day, -(n * 10), CAST(GETDATE() AS DATE)),
    30000 + (ABS(CHECKSUM(NEWID())) % 70000),
    CASE WHEN n % 10 = 0 THEN NULL ELSE (n % 8) + 1 END
FROM tally;
GO

---------------------------
-- 20 PROYECTOS
---------------------------
;WITH p AS (
    SELECT TOP (20) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n 
    FROM sys.all_objects
)
INSERT INTO dbo.Projects (ProjectName, StartDate, EndDate, LeaderEmployeeID)
SELECT
    'Project ' + RIGHT('00' + CAST(n AS VARCHAR(2)),2),
    DATEADD(day, - (n * 20), GETDATE()),
    DATEADD(day, (n * 20), GETDATE()),
    CASE WHEN n % 4 = 0 THEN NULL 
         ELSE (SELECT TOP 1 EmployeeID FROM dbo.Employees ORDER BY NEWID()) END
FROM p;
GO

---------------------------
-- 200 EVALUACIONES RANDOM
---------------------------
INSERT INTO dbo.Evaluations (EmployeeID, EvalDate, Score, Comments)
SELECT TOP (200)
    E.EmployeeID,
    DATEADD(month, -(ROW_NUMBER() OVER(ORDER BY E.EmployeeID) % 12), GETDATE()),
    (ABS(CHECKSUM(NEWID())) % 5) + 1,
    'Evaluación para empleado ' + CAST(E.EmployeeID AS VARCHAR(10))
FROM dbo.Employees E
ORDER BY NEWID();
GO

---Ejercicio 1: INNER JOIN consulta los nombres de empleados junto con el nombre de su departamento.

SELECT  * 
from Departments; 
select *
from Employees;
select * 
from Projects;
select *
from Evaluations;

SELECT e.firstname, e.lastname, d.DepartmentName
from Employees e
INNER JOIN Departments d on e.DepartmentID = d.DepartmentID; 

---LEFT JOIN: Lista todos los empleados y los proyectos que lideran, mostrando NULL si no lideran ninguno
SELECT e.firstname, e.lastname, p.ProjectName
from Employees e
LEFT JOIN Projects p on e.EmployeeID = p.LeaderEmployeeID;

---RIGHT JOIN: Muestra todos los proyectos y los nombres de sus líderes, incluyendo proyectos sin líder.
SELECT p.projectname,e.firstname, e.lastname
from Projects p
LEFT JOIN Employees e
	ON p.LeaderEmployeeID=e.EmployeeID;

---FULL JOIN: Combina empleados y evaluaciones para ver todos los registros, incluso sin coincidencias
SELECT * 
from Evaluations ev
FULL JOIN Employees e 
	ON ev.EvalID = e.EmployeeID;

---Subconsulta: Encuentra los empleados que trabajan en departamentos con más de 10 empleados.
SELECT e.lastname, e.firstname, e.DepartmentID
from Employees e 
where DepartmentID IN (select DepartmentID 
						from Employees 
						where DepartmentID is not null
						group by DepartmentID
						having count (*) >10
);
