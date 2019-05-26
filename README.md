# slutprojektvt19webbserver

# Projektplan

## 1. Projektbeskrivning
Projeket skall bestå av ett forum som ska uppfylla flera olika funktioner. Man ska kunna skapa ett konto, logga in och logga ut. Användare ska även kunna redigera sin profil, skapa inlägg, redigera sina inlägg och lägga till taggar till sina inlägg. Sidan ska också vara säker på det sättet att enbart folk som är ägare till ett inlägg eller en profil ska ha tillåtelse att redigera det. 

## 2. Vyer (sidor)
1) Startsida
2) Profilsida
3) Registrering
4) Redigera profil
5) Inläggssidor

## 3. Funktionalitet (med sekvensdiagram)
1) Registering
![alttext](https://github.com/itggot-samuel-bach/slutprojektvt19webbserver/blob/master/resources/register_sequence.PNG)
2) inlogg samt utloggning
![alttext](https://github.com/itggot-samuel-bach/slutprojektvt19webbserver/blob/master/resources/login_sequence.PNG)
3) Posta inlägg
![alttext](https://github.com/itggot-samuel-bach/slutprojektvt19webbserver/blob/master/resources/profile_post_sequence.PNG)
4) Redigera inlägg och användarprofiler.
## 4. Arkitektur (Beskriv filer och mappar)
Min arkitektur består av ett flertal mappar. Dessa är: db (database.db i), functions (functions rb i), public (css och img i den), resources (med bilder), views (med alla slim filer i) och sedan app.rb som står själv. Här följer en bild som visar mappstrukturen.
![alttext](https://github.com/itggot-samuel-bach/slutprojektvt19webbserver/blob/master/resources/arkitektur.PNG)
## 5. (Databas med ER-diagram)
Det här är min databas illustrerat med ett er-diagram:
![allttext](https://github.com/itggot-samuel-bach/slutprojektvt19webbserver/blob/master/resources/ER_DIAGRAM.PNG)
