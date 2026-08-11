/* 
* Copyright (c) 2025 Horstaufmental
* SPDX-License-Identifier: MPL-2.0
*/

F64 CDateToMSec(F64 delta) {
  return delta * 86400000.0;
}

I64 IterateDir(U8 *folder) {
  I64 count = 0;
  U8 *to_count = StrPrint(NULL, "%s/frame_%05d.txt", folder, 1);
  // "%s : %s\n",folder,to_count;  


  I64 i;
  for (i=2;FileFind(to_count)!=FALSE;i++) {
    Free(to_count);
    ++count;
    to_count = StrPrint(NULL, "%s/frame_%05d.txt", folder, i);
    // "%s : %s\n",folder,to_count;
  }
  return count;
}


I64 PlayASCIIFrames(F64 fps) {
  WinFocus;
  WinMax;
  WinBorder;

  I64 total_frames = IterateDir("ascii_frames");

  if (total_frames <= 0) {
    "No frames found!\n";
    return -1;
  }

  I64 frame;
  
  for (frame=1;frame<=total_frames;++frame) {
    U8 *path = StrPrint(NULL, "%s/frame_%05d.txt", "ascii_frames", frame);
    I64 size;
    U8 *data = FileRead(path, &size);

    if (!data) {
      Free(path);
      break;
    }

    DocClear;
    "%s",data;

    Free(data);
    Free(path);
    
    "Frame#%d\n",frame;

    //F64 elapsed_ms = CDateToMSec(end - start);
    //I64 remaining = (delay - elapsed_ms)(I64);

    /*if (remaining > 0)
      Sleep(remaining);
    */
    Sleep(fps);
  }
}

PlayASCIIFrames(30.66);
