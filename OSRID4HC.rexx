 /* rexx */                                                             00050000
 /* Input DD : FILEIN,which is produced by another program OSRHC        00050100
               contains lines of either a dataset name or a pair of     00050200
               a class and a profile                                    00050300
    Output DD: IDS4OSR, lists all 'HC'ed dataset and resource names     00050400
               with all IDs having an authority to access to            00050500
    optionally, specify RSCEXPND to list all specific profiles          00050700
                if a profile is a generic one                           00051000
                                  andrewJ 2008 Mar 31                   00051200
    updated to check the least authority                                00051300
                                  andrewJ 2008 Apr 08 */                00051400
 /* updated to take group cics transaction class into consideration     00051500
                                  andrewJ 2008 Apr 24 */                00051600
 /* updated to check controlled transaction id                          00051700
                                  andrewJ 2008 Apr 28 */                00051800
 /* updated to provide an option: TRNEXPND to specify whether to        00051908
    list all transactions or not                                        00052008
                                  andrewJ 2008 Apr 29 */                00052108
 /* updated to also check if it reaches a section end to prevent        00052213
    the scan from running to far in case there is a '*' specified       00052313
                                  andrewJ 2008 Apr 30 */                00052413
 /* updated to skip 'no entries'                                        00052516
                                  andrewJ 2008 Apr 30 */                00052716
 arg arg1                                                               00052816
                                                                        00052916
 /* create list header here */                                          00053016
 queue ' *** OSRs privilege IDs for' mvsvar(sysname) ,                  00053116
       'on' date()  'at'  time() 'by' sysvar(sysuid) ,                  00053216
           '*** '                                                       00053316
 "execio 1 diskw ids4osr"                                               00054000
                                                                        00054100
 /* read in all group class data & form an array */     /*20080428*/    00054200
  "execio * diskr grpclass (stem rec. finis"            /*20080428*/    00054400
 j = 0                                                  /*20080428*/    00054500
 grp. = 0                                               /*20080428*/    00054600
 do i = 1 to rec.0                                      /*20080428*/    00054700
    if word(rec.i,1) \= grp.j then                      /*20080428*/    00054800
      do                                                /*20080428*/    00054900
       grp.0 = grp.0 + 1                                /*20080428*/    00055000
       j = j + 1                                        /*20080428*/    00055100
       k = 1                                            /*20080428*/    00055200
      end                                               /*20080428*/    00055300
    grp.j   = word(rec.i,1)                             /*20080428*/    00055400
    grp.j.k = word(rec.i,2)                             /*20080428*/    00055500
    l = 1                                               /*20080429*/    00055611
    do l = 1 to 5                                       /*20080429*/    00055711
      if word(rec.i,l+2) = '' then leave                /*20080429*/    00055811
      else                                              /*20080429*/    00055911
       do                                               /*20080429*/    00056011
          grp.j.k.l = word(rec.i,l+2)                   /*20080429*/    00056111
          grp.j.k.0 = grp.j.k.0 + 1                     /*20080429*/    00056211
       end                                              /*20080429*/    00056311
    end                                                 /*20080429*/    00056411
    grp.j.0 = grp.j.0 + 1                               /*20080428*/    00056511
    k = k + 1                                           /*20080428*/    00056611
 end                                                    /*20080428*/    00057011
                                                                        00059000
 do forever   /* loop for all recs of input file */                     00060000
  "execio 1 diskr filein"                                               00070000
      if rc \= 0  then                                                  00080000
        do                                                              00090000
         if rc =2 then leave                                            00100000
         else                                                           00110000
          do                                                            00120000
           say execname '"EXECIO DISKR" Exit=' rc                       00130000
          end                                                           00140000
        end                                                             00150000
   pull rec                                                             00160000
                                                                        00160109
   gyes = 0                                         /*20080424*/        00160200
                                                                        00160300
   if words(rec) = 2 then /*from 1 to 2 for the extra auth field*/      00161000
    do                                                                  00162000
      dsn = word(rec,1)                                                 00170000
      auth = substr(word(rec,2),1,1) /* the least authority to check */ 00180000
      upper auth         /* for comparison later */                     00190000
      if auth = 'R' then auth = 'V' /*make it larger than U*/           00190100
      call rtn_dataset   /* process dataset profiles */                 00191000
    end                                                                 00191100
   else                                                                 00191200
    do                                                                  00191300
      class = word(rec,1)  /* class name */                             00191400
      rprof = word(rec,2)  /* profile name */                           00191500
      auth = substr(word(rec,3),1,1) /* the least authority to check */ 00191600
      upper auth     /* for a comparsion later */                       00191700
      if auth = 'R' then auth = 'V' /*make it larger than U*/           00191800
      call rtn_resource  /* process resource profiles */                00191900
    end                                                                 00192000
                                                                        00193000
 end /* end of do forever */                                            00480000
                                                                        00490000
 "execio 0 diskr filein (finis"                                         00500000
 "execio 0 diskw ids4osr (finis"                                        00510000
                                                                        00520000
 exit 0                                                                 00530000
                                                                        00531000
 rtn_dataset: /* routine to process dataset profiles */                 00532000
   outrec =  dsn || ','                                                 00532100
   outsec = ''                /*20080424 accumulate id*/                00532206
   x = outtrap('prof.')                                                 00532306
   "ld da('"dsn"') ge auth "  /* check authority to the file */         00532406
   x = outtrap('off')                                                   00532506
                                                                        00532606
   do  i = 1 to prof.0                                                  00532706
     if word(prof.i,1) = 'ID' & ,                   /*20080430*/        00532814
        word(prof.i,2) = 'ACCESS' & ,               /*20080430*/        00532914
        word(prof.i,3) = 'CLASS'  & ,               /*20080430*/        00533014
        words(prof.i) > 4 then leave                /*20080430*/        00533114
     call rtn_extract_data                                              00534006
   end /* of do to prof.0 */                                            00535000
 return                                                                 00535100
                                                                        00535200
 rtn_resource: /* routine to process resource profiles */               00535300
   if grp.0  \= 0  then                             /*20080428*/        00535600
    do                                              /*20080428*/        00535700
      do g = 1 to grp.0                             /*20080428*/        00535800
        if class = grp.g then                       /*20080428*/        00535900
         do                                         /*20080424*/        00536000
           gyes = 1                                 /*20080424*/        00536100
           if rprof = '*' then                      /*20080424*/        00536200
            do                                      /*20080424*/        00536300
             x = outtrap('gtrn.')                   /*20080424*/        00536400
             "sr nomask cla("class") "              /*20080424*/        00536500
             x = outtrap('off')                     /*20080424*/        00536600
             do j = 1 to gtrn.0                     /*20080424*/        00536700
               rprof = word(gtrn.j,1)               /*20080424*/        00536800
               call rtn_rsc_granule                 /*20080424*/        00537000
             end                                    /*20080424*/        00537100
            end                                     /*20080424*/        00537200
           else call rtn_rsc_granule                /*20080424*/        00537300
           leave                                    /*20080428*/        00537400
         end                                        /*20080424*/        00537500
        else if class < grp.g then leave            /*20080428*/        00537600
      end /* of do to grp.0 */                      /*20080428*/        00537700
    end /* of if grp.0 \=0 */                       /*20080428*/        00537800
                                                                        00537903
   if gyes = 0 then                                /*20080428*/         00538004
    do                                             /*20080428*/         00538104
      if arg1 \= 'RSCEXPND ' then                                       00538204
         call rtn_rsc_granule                                           00538304
      else                                                              00538404
       do                                                               00538504
         parse var rprof highname '.' .                                 00538604
         x = outtrap('spec.')                                           00538704
         "sr mask("highname") cla("class") " /* all specific profiles */00538804
         x = outtrap('off')                                             00538904
         do j = 1 to spec.0                                             00539004
           rprof = word(spec.j,1)                                       00539104
           call rtn_rsc_granule                                         00539204
         end                                                            00539304
       end                                                              00539404
    end                                            /*20080428*/         00539505
 return                                                                 00539604
                                                                        00539704
 rtn_rsc_granule:                                                       00539804
   if gyes = 1 & arg1 = 'TRNEXPND' then        /*20080429*/             00539908
     do                                        /*20080428*/             00540004
     outrec =  class || ',' || rprof || '_'    /*20080424*/             00540104
     end                                       /*20080428*/             00540204
   else                                        /*20080424*/             00540304
     outrec =  class || ',' || rprof || ','    /*20080424*/             00540404
   x = outtrap('prof.')                                                 00540504
   "rl "class" "rprof" auth "  /* check authority to the file */        00540604
   x = outtrap('off')                                                   00540704
                                                                        00540804
   outsec = ''                /*20080424 accumulate id*/                00540904
                                                                        00541004
   do  i = 1 to prof.0                                                  00541104
     if word(prof.i,1) = 'ID' & ,                   /*20080430*/        00541214
        word(prof.i,2) = 'ACCESS' & ,               /*20080430*/        00541314
        word(prof.i,3) = 'ACCESS' & ,               /*20080430*/        00541414
        words(prof.i) > 4 then leave                /*20080430*/        00541514
     call rtn_extract_data                                              00541604
   end /* of do to prof.0 */                                            00541704
 return                                                                 00541804
                                                                        00541904
 rtn_extract_data:  /*extract wanted data*/                             00542004
   select                                                               00542104
     when substr(prof.i,1,23) = 'INFORMATION FOR DATASET' then          00542204
         outrec = outrec || word(prof.i,4) || ','                       00542304
     when word(prof.i,1) = 'RESOURCES' & ,          /*20080424*/        00542404
          word(prof.i,2) = 'IN'        & ,          /*20080424*/        00542504
          word(prof.i,3) = 'GROUP' then             /*20080424*/        00542604
       do                                           /*20080424*/        00542704
         i = i + 2                                  /*20080424*/        00542804
         tt = 1                                     /*20080424*/        00542904
         trn.0 = 0                                  /*20080424*/        00543004
         do forever                                 /*20080424*/        00543104
           if word(prof.i,1) /= '' then             /*20080424*/        00543204
             do                                     /*20080424*/        00543304
              xxxx = word(prof.i,1)                 /*20080428*/        00543404
              parse var xxxx sysn '.' trnn          /*20080428*/        00543504
              if trnn = '' then trnn = sysn         /*20080429*/        00543610
              if grp.g.0 \= 0 then                  /*20080428*/        00543710
               do                                   /*20080428*/        00543810
                do gg = 1 to grp.g.0                /*20080428*/        00543910
                 if trnn = grp.g.gg then            /*20080428*/        00544010
                  do                                /*20080428*/        00544110
                   unwant = 0                       /*20080429*/        00544211
                   if grp.g.gg.0 \= 0 then          /*20080429*/        00544311
                     do g3  = 1 to grp.g.gg.0       /*20080429*/        00544411
                      parse var grp.g.gg.g3 '-' xxx /*20080429*/        00544511
                      if xxx = sysn then            /*20080429*/        00544611
                        do                          /*20080429*/        00544711
                          unwant = 1                /*20080429*/        00544811
                          leave                     /*20080429*/        00544911
                        end                         /*20080429*/        00545011
                     end                            /*20080429*/        00545111
                   if unwant = 1 then leave         /*20080429*/        00545211
                   trn.tt = xxxx || ','             /*20080428*/        00545311
                   trn.0  = trn.0 + 1               /*20080424*/        00545411
                   tt = tt + 1                      /*20080424*/        00545511
                   leave  /* jump out of the loop*/ /*20080428*/        00545611
                  end                               /*20080428*/        00545711
                 else if trnn < grp.g.gg then leave /*20080428*/        00545811
                end /* of do to  grp.g.0 */         /*20080428*/        00545911
               end                                  /*20080428*/        00546011
              i = i + 1                             /*20080424*/        00546111
             end                                    /*20080424*/        00546211
           else                                     /*20080424*/        00546311
              leave   /* jump out of the loop */    /*20080424*/        00546411
         end /*of forever*/                         /*20080424*/        00546511
       end  /*of when*/                             /*20080424*/        00546611
     when ( word(prof.i,1) = 'ID' | word(prof.i,1) = 'USER')  & ,       00546711
          word(prof.i,2) = 'ACCESS' & ,                                 00546811
          words(prof.i) < 5 then                                        00546911
       do                                                               00547011
         i = i + 2  /* skip this and '------- -------' */               00547111
         do forever                                                     00547211
           if word(prof.i,1) /= '' then                                 00547311
             do                                                         00547411
              if word(prof.i,1) = 'NO' & ,                              00547516
               ( word(prof.i,2) = 'USERS' | ,                           00547616
                 word(prof.i,2) = 'ENTRIES' ) then  /*20080430*/        00547716
                 leave                                                  00547816
              acc = substr(word(prof.i,2),1,1)  /* 1st char */          00547916
              upper acc                                                 00548016
              if acc = 'R' then acc = 'V' /*make it larger than U*/     00548116
              if acc <= auth then                                       00548216
                outsec = outsec || word(prof.i,1) || '(' || ,           00548316
                         word(prof.i,2) || '),'                         00548416
              i = i + 1                                                 00548516
             end                                                        00548616
           else                                                         00548716
             do                                                         00548816
              if gyes = 1 then                         /* 20080424 */   00548916
               do                                      /* 20080429 */   00549016
                if trn.0 \= 0 & arg1 = 'TRNEXPND' then /* 20080429 */   00549116
                  do tt = 1 to trn.0                   /* 20080424 */   00549216
                   queue outrec ||  trn.tt || outsec   /* 20080424 */   00549316
                   "execio 1 diskw ids4osr"            /* 20080424 */   00549416
                  end                                  /* 20080429 */   00549516
                else if trn.0 \= 0 then                /* 20080429 */   00549616
                  do                                   /* 20080429 */   00549716
                   queue outrec || outsec              /* 20080429 */   00549816
                   "execio 1 diskw ids4osr"            /* 20080429 */   00549916
                  end                                  /* 20080429 */   00550016
               end                                     /* 20080429 */   00550116
              else                                     /* 20080424 */   00550216
               do                                      /* 20080424 */   00550316
                queue outrec || outsec    /* concat. outsec 20080424*/  00550416
                "execio 1 diskw ids4osr"                                00550516
               end                                /* 20080424 */        00550616
              leave   /* jump out of the loop */                        00550716
             end /* of else */                                          00550816
         end /*do forever*/                                             00550916
       end                                                              00551016
    otherwise                                                           00551116
   end /* of select */                                                  00551216
 return                                                                 00552011
                                                                        00560011
