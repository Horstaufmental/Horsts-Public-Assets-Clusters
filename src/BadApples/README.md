# Bad Apple

*Rule 82 of the Internet has stated:*

> If something has two colors, it can play "Bad Apple!!"

Attempts on playing **[Bad Apple](https://www.youtube.com/watch?v=FtutLA63Cp8)** on wacky, non-standard environments
to/for regular people or use cases.

## What is "Bad Apple!!"?

<div align="center">
    <picture>
        <img src="https://cdn.donmai.us/original/dc/7e/__kazami_yuuka_and_elly_touhou_drawn_by_clem_calmeremerald__dc7e68190cedccb6a2ccc53503e04019.png" width="100%">
    </picture>
</div>

*[Elly](https://en.touhouwiki.net/wiki/Elly), a Touhou character that appears as the Stage 3 boss in Lotus Land Story. Best remembered for her stage theme, Bad Apple!!.*

*From Wikipedia:*
**"Bad Apple!!"**, one of the most famous pieces of [*Touhou*](https://en.wikipedia.org/wiki/Touhou_Project) music, was originally composed by [ZUN](https://en.wikipedia.org/wiki/ZUN_(video_game_developer)) as the Stage 3 theme for the fourth game, [*Touhou Gensokyo ~ Lotus Land Story*](https://en.touhouwiki.net/wiki/Lotus_Land_Story), released on August 14, 1998. According to ZUN, he aimed for a song that sounded "as old-fashioned as possible".

The song saw a massive surge in popularity following a 2007 arrangement by the doujin circle Alstroemeria Records titled "Bad Apple!! feat. [nomico](https://en.wikipedia.org/wiki/Nomico)". Arranged by Masayoshi Minoshima with vocals by the singer nomico, this version was released on the album *Lovelight* on May 20, 2007, at the 4th [Hakurei Shrine Reitaisai](https://en.touhouwiki.net/wiki/Reitaisai). The lyrics, written by Haruka, utilize the English idiom "bad apple" (referring to a rotten apple that spoils the barrel) to depict a protagonist struggling with apathy, introspection, and a desire to completely "change to white" or "turn to black."

The visual component that cemented the song's internet fame began on June 8, 2008, when a user named Μμ uploaded a crude storyboard video to [Niconico](https://en.wikipedia.org/wiki/Niconico) based on a shortened version of the song, asking for someone to animate it. On October 27, 2009, a Niconico user named Anira (Japanese: あにら) published a completed black-and-white shadow play animation based on the storyboard. The video, which features characters such as [Reimu Hakurei](https://en.touhouwiki.net/wiki/Reimu_Hakurei) and [Marisa Kirisame](https://en.touhouwiki.net/wiki/Marisa_Kirisame) transitioning fluidly while dancing, quickly gained popularity, reaching #1 on the Niconico daily rankings on November 15, 2009. Alstroemeria Records themselves praised the video, describing the motion as beautiful. By March 2023, Anira's shadow art video had achieved over 30 million views on Niconico alone, making it the most-viewed Touhou-related video on the site.

The song and its shadow art video also became a staple in the demoscene and retrocomputing communities, often used to demonstrate the capabilities of hardware presumed incapable of playing back full-motion video. Peter Dell, a programmer who contributed to a port, described the video as having become a graphical equivalent to "Hello, World!" programs for retro platforms.

## Current Implementation

### [HolyC Apple](./HolyCApple)

Written in **Holy C** for **TempleOS**. Prints out sequence of frames in ASCII text.
(Also doubles down as an ASCII player)

### [Bad UEFI](./BadUEFI)

Written in **Rust**, designed to be run in an **UEFI** environment.
Uses a sequence of images in a tarball extracted at runtime to draw in a framebuffer.

> [!NOTE]
> 'Bad UEFI' is licensed under GNU General Public License v3+

## License

All implementations listed above **(UNLESS SPECIFIED OTHERWISE)** are licensed under the **MPL-2.0** (Mozilla Public License Version 2.0).

See [LICENSE](/LICENSE) for full details.
