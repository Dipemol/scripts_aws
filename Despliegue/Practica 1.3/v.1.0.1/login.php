<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Hola Mundo</title>
    <style>
        body {
            background-color: blue;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
    </style>
</head>
<body>
    <form>
        <label for="user">Username:</label><br>
        <input type="text" id="user" name="user" required><br>
        <label for="pass">Password:</label><br>
        <input type="password" id="pass" name="pass" required><br>
        <button type="submit">Login</button>
    </form>
</body>
</html>