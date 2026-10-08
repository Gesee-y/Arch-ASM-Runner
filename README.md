# Archer: Interpreteur de pseudo-ASM pour les cours d'architecture des ordinateur

Le cours d'architecture des ordinateurs dispenser dans a l'Ecole Nationale Superieur Polytechnique de Yaounde au Premiere annee de la filiere Humanite Numerique est redouter pour son chapitre sur l'assembleur.

En effet, pour comprendre en profondeur le fonctionnement du processeur, les etudiants sont amener a ecrire du code pseudo assembleur designer pour l'apprentissage.
Cependant, verifier ce code ou le comprendre est un vrai probleme pour les etudiants qui ont enormement de mal a saisir la logique.

C'est pourquoi **Archer** existe.
Il permet d'executer le code pseudo assembleur et donne l'occasion au etudiant de visualiser l'execution du programme.

Archer est un binaire unique et peut etre embarquer ou compiler depuis le code source.

## Exemple rapide

Ecrire ceci dans un fichier `first.arc`
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