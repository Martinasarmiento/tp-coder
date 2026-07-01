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

/*
TP1 - JOINs y Subconsultas

Este script implementa los distintos tipos de JOIN solicitados:
- INNER JOIN para mostrar solo registros relacionados.
- LEFT JOIN para conservar todos los empleados.
- RIGHT JOIN para conservar todos los proyectos.
- FULL JOIN para incluir todos los registros de ambas tablas.
- Subconsulta para identificar empleados pertenecientes a departamentos con más de 10 empleados.

Además, el script incluye claves foráneas, índices, restricciones de integridad y CTEs con funciones de ventana para generar datos de prueba.
*/

-- Ejercicio 1: INNER JOIN
-- Devuelve únicamente los empleados que pertenecen a un departamento existente.
SELECT e.FirstName, e.LastName, d.DepartmentName
FROM Employees e
INNER JOIN Departments d
ON e.DepartmentID = d.DepartmentID;

-- Ejercicio 2: LEFT JOIN
-- Devuelve todos los empleados, incluso aquellos que no lideran proyectos.
SELECT e.FirstName, e.LastName, p.ProjectName
FROM Employees e
LEFT JOIN Projects p
ON e.EmployeeID = p.LeaderEmployeeID;

-- Ejercicio 3: RIGHT JOIN
-- Devuelve todos los proyectos, incluso aquellos que no tienen líder asignado.
SELECT p.ProjectName, e.FirstName, e.LastName
FROM Employees e
RIGHT JOIN Projects p
ON e.EmployeeID = p.LeaderEmployeeID;

-- Ejercicio 4: FULL JOIN
-- Devuelve todos los empleados y todas las evaluaciones, existan o no coincidencias entre ambas tablas.
SELECT *
FROM Employees e
FULL JOIN Evaluations ev
ON e.EmployeeID = ev.EmployeeID;

---Subconsulta: Encuentra los empleados que trabajan en departamentos con más de 10 empleados.
SELECT e.FirstName,
       e.LastName,
       e.DepartmentID
FROM Employees e
WHERE e.DepartmentID IN (
    SELECT DepartmentID
    FROM Employees
    GROUP BY DepartmentID
    HAVING COUNT(*) > 10
);