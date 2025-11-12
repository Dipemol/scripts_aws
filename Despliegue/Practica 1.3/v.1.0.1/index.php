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

        h1 {
            color: white;
            font-size: 3em;
            transition: transform 0.6s ease;
            cursor: pointer;
        }

        h1.rotar {
            transform: rotate(360deg);
        }
    </style>
</head>
<body>
    <a href="login.php">
        <h1 id="hola">Hola Mundo</h1>
    </a>
    <script>
        const hola = document.getElementById("hola");

        hola.addEventListener("mouseover", () => {
            hola.classList.add("rotar");
        });

        hola.addEventListener("mouseout", () => {
            hola.classList.remove("rotar");
        });
    </script>
</body>
</html>
