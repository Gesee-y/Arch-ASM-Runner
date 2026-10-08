# Archer : Interprète de pseudo-ASM pour les cours d'architecture des ordinateurs

Le cours d'architecture des ordinateurs dispensé à l'École Nationale Supérieure Polytechnique de Yaoundé en première année de la filière Humanités Numériques est redouté pour son chapitre sur l'assembleur.

En effet, pour comprendre en profondeur le fonctionnement du processeur, les étudiants sont amenés à écrire du code pseudo-assembleur conçu pour l'apprentissage.
Cependant, vérifier ce code ou le comprendre est un vrai problème pour les étudiants qui ont énormément de mal à saisir la logique.

C'est pourquoi **Archer** existe.
Il permet d'exécuter le code pseudo-assembleur et donne l'occasion aux étudiants de visualiser l'exécution du programme.

Archer est un binaire unique et peut être embarqué ou compilé depuis le code source.

## Exemple rapide

Écrire ceci dans un fichier `first.arc` :
```asm
READ A
READ B

ADD A, B
PRINT A
``` 

et puis lancer avec:

```bash
archer -m:1 r first.arc
```

## License

Ce code est sous la license MIT.