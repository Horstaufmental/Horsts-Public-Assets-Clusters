# HolyC Apple

*Rule 82 of the Internet has stated:*

> If something has two colors, it can play "Bad Apple!"

Which means it's possible inside the greatest operating system of all time, TempleOS!

A simple ASCII frames player made specifically to play the iconic [Bad Apple!!](https://www.youtube.com/watch?v=FtutLA63Cp8&list=RDFtutLA63Cp8&start_radio=1&pp=ygUJYmFkIGFwcGxloAcB) inside of your divine TempleOS system.

I only created this to kill boredom so don't expect much from it.

# What is "Bad Apple!!"?

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

# Installation

## 1. Through an ISO file

1. **Download the latest release from [GitHub Releases](https://github.com/Horstaufmental/Horsts-Public-Assets-Clusters/releases)**

2. **Boot the ISO file with a VM of choice**
For example, with QEMU:
```bash
    qemu-system-x86_64 -cdrom TOS_BadApple.ISO -m 4G -enable-kvm -cpu host -smp 8
```

3. **Run the program**
You can manually navigate and `include` the program yourself, or run:
```c
    Cd("BadApple");
    #include "badapple.HC";
```

## 2. Manual Installation (for existing systems)

>[!NOTE]
>This installation guide assumes you've installed TempleOS with the QEMU emulator on a `.qcow2` image.
>Although mounting methods might differ for each image types/systems, the actual installation should work the same.

0. **Ensure you have the `qemu-utils` package installed.**
```bash
    sudo apt install qemu-utils  # For Debian/Ubuntu
    # or
    sudo yum install qemu-img    # For Red Hat/CentOS
    # or
    sudo pacman -S qemu-img      # For Arch-based systems
    
    # For other systems, please check your OS's repository.
```
1. **Load the NBD kernel module.**
The `max_part` parameter specifies the maximum number of partitions the NBD device can expose. 
```bash
    sudo modprobe nbd max_part=8 # Adjust max_part as needed
```

2. **Connect your QCOW2 image to an NBD device (e.g., /dev/nbd0).**
Replace `/path/to/your/image.qcow2` with the actual path to your QCOW2 file.
```bash
    sudo qemu-nbd --connect=/dev/nbd0 /path/to/your/image.qcow2
```

3. **List the partitions available on the connected NBD device.**
Usually, TempleOS will be installed on `/dev/nbd0p1`.
```bash
    $ lsblk /dev/nbd0
    NAME     MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
    nbd0      43:0    0     1G  0 disk 
    ├─nbd0p1  43:1    0 517.7M  0 part 
    └─nbd0p2  43:2    0   502M  0 part 
```

4. **Create a mount point and then mount the partition from the QCOW2 image.**
```bash
    sudo mkdir /mnt/qcow2_mount
    sudo mount /dev/nbd0p1 /mnt/qcow2_mount
```

5. **Create a new directory inside TempleOS's home directory.**
You can name the directory anything but we'll choose `BadApple` for this tutorial.
```bash
    sudo mkdir /mnt/qcow2_mount/Home/BadApple
```

6. **Install the components:**
```bash
    sudo cp src/badapple.HC /mnt/qcow2_mount/Home/BadApple/
    sudo tar -xvf src/ascii_frames.tar.xz -C /mnt/qcow2_mount/Home/BadApple/
```

7. **Unmount the partition and Disconnect the NBD device**
```bash
    sudo umount /mnt/qcow2_mount
    sudo qemu-nbd --disconnect /dev/nbd0
```

# Usage

1. **Boot up TempleOS**
Make sure to boot into `Drive C` once inside the bootloader.
```bash
    qemu-system-x86_64 -cdrom TOS_Distro.ISO -hda /path/to/your/image.qcow2 -m 4G -enable-kvm -cpu host -smp 8
```

2. **Run the program**
You can manually navigate and `include` the program yourself, or run:
```c
    Cd("BadApple");
    #include "badapple.HC";
```

3. **You've successfully played Bad Apple inside TempleOS!**
*Performance may differ depending on the system, in that case then that's a you problem*

# FAQ

## Are there any sounds in this?
Sadly, no. I don't have the time to add them in.
For those who are interested in implementing the sounds in, [You should give this a look.](https://tinkeros.github.io/WbTempleOS/LiveHelp/Sound.html#l1)

## Can I play anything else other than Bad Apple?
Absolutely, although it'll require a bit of setup. You'll need to extract all the frames from your video then converting them to ASCII text files.
```bash
    mkdir extracted_frames
    mkdir ascii_frames
    ffmpeg -i input.mp4 -r 30 extracted_frames/frame%04d.png # change -r to desired framerate
```
```bash
    for f in extracted_frames/*.png; do
        jp2a --width=80 "$f" > "ascii_frames/$(basename "$f" .png).txt"
    done
```
Then replace the current `ascii_frames` folder with your new ones.
```bash
    sudo mv ascii_frames/ /mnt/qcow2_mount/Home/BadApple/ascii_frames
```
If your extracted video are not 30fps, make sure to set your FPS inside `badapple.HC`
```c
    PlayASCIIFrames(30); -- change to your desired FPS
```

## I don't want an ASCII player, are there other methods?
You can take a look at some existing implementations (that are better than mine) like [this one](https://github.com/SKPG-Tech/TOS-Bad-Apple).
