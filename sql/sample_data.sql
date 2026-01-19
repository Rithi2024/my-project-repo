USE flutter_exam;

-- Insert categories
DECLARE @i INT = 1;
WHILE @i <= 20
BEGIN
  INSERT INTO Categories(name, description)
  VALUES (CONCAT(N'ប្រភេទ ', @i), CONCAT('Category ', @i));
  SET @i += 1;
END

-- Insert products
DECLARE @p INT = 1;
DECLARE @catCount INT = (SELECT COUNT(*) FROM Categories);

WHILE @p <= 500
BEGIN
  DECLARE @cid INT = ((@p - 1) % @catCount) + 1;

  INSERT INTO Products(name, description, category_id, price, image_url, updated_at)
  VALUES (
    CONCAT(N'ទំនិញ ', @p),
    CONCAT('Product desc ', @p),
    @cid,
    CAST(((@p % 200) + 1) * 0.5 AS DECIMAL(10,2)),
    CONCAT('/images/p', RIGHT('000' + CAST((@p % 20) + 1 AS VARCHAR(10)), 3), '.jpg'),
    GETDATE()
  );

  SET @p += 1;
END
