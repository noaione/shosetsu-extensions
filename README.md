# N4O Shosetsu Extensions

A collection of Shosetsu extensions that I've made as an extra accompanion for the upstream Shosetsu extensions.

It was originally a fork of the upstream repo but since they moved to GitLab, I decided to detach the fork and remove the upstream extension from this repository so there is no duplicates.

You can report any problem in the Issues tab, you can also try to request an extension (Depends on how hard it is to implement).

You can also try to contact me via Discord: **N4O#8868**

## Adding to Shosetsu
To add this repository to Shosetsu, follow this instructions:
1. Open More
2. Open Repositories
3. Copy the following link: `https://raw.githubusercontent.com/noaione/shosetsu-extensions/repo`
4. Click `Add`
5. Paste the above link to `Repository URL` and name the `Repository name` into `N4O` or something similar
6. Refresh your extension list
7. Install the extension you want

## Extensions
1. bakapervert
2. Kuro Kurori's Lounge
3. Europa is a cool moon
4. Reigokai - Isekai Lunatic
5. bayabusco translation
6. Experimental Translations
7. ShiroKun's Translation
8. Shiru Sekai Translations
9. Craneanime Translation
10. Toasty Translations
11. Light Novels Translations
12. Hellping
13. Skythewood
14. Ainushi
15. CClaw Translations
16. Glucose Translations
17. SHM Translations
18. AYA Translation
19. Tintan

**Madara**-based:
1. Fans Translations
2. Zetro Translation<br />
   Replace with my version since I did some lib fix sometimes.

Please note that I'm creating for the stuff I'm reading myself, if some pages does not work please open up a new Issue so I can look up how to solve it.

### Tested and Working
The following list is the novel I used for testing and it's working properly (it's also what I read.)

1. bakapervert
   1. Arifureta
2. Kuro Kurori's
   1. The Middle-aged Man who just Returned from Another World Melts his Fathercon Daughters with his Paternal Skill
3. Europa is a cool moon
   1. Chronicles of an Aristocrat Reborn in Another World
4. Reigokai
   1. Tsuki ga Michibiku Isekai Douchuu
5. Bayabusco Translation
   1. The Demon King Seems to Conquer the World
6. Experimental Translations
   1. Grimoire Master of an Everchanging World
7. ShiroKun's Translation
   1. Chiyu Mahou no Machigatta Tsukaikata \~Senjou wo Kakeru Kaifuku Youin\~
8. Shiru Sekai Translations
   1. Chiyu Mahou no Machigatta Tsukaikata \~Senjou wo Kakeru Kaifuku Youin\~
9. Craneanime Translation
   1. Reborn Girl Starting a New Life In Another World As a Seventh Daughter
   2. The Novice Alchemist’s Store
10. Toasty Translations
    1. I'm Not Even An Otome Game Mob Character!
11. Light Novels Translations
    1.  100 Things I Don't Know About My Senpai
12. Hellping
    1.  The Angel Next Door Spoils Me Rotten

Above list should be working as intended when you open up the chapter, for Madara-based extension it should be working just fine.

### Specials Info
1. Hellping<br />
   This extension use a custom API made specifically for Shosetsu since the website design is so broken and hard to parse. See [`extras`](https://github.com/noaione/shosetsu-extensions/tree/dev/extras) folder for more info.
2. CClaw Translations<br />
   Part of this extension use the custom API. See [`extras`](https://github.com/noaione/shosetsu-extensions/tree/dev/extras) folder for more info.

## Contributing

Contribution is allowed, as long as it is not available in the upstream repository because it is useless.

Please make sure to test the extension using my fork of [extension-tester](https://github.com/noaione/shosetsu-ext-tester)

```sh
$ java -jar extension-tester.jar src/en/NewExtension.lua
```

For ID, you can just randomly generate it.
