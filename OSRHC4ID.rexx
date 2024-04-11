 /* rexx */                                                             00010000
 /* Input DD : FILEIN,which is produced by another program OSRHC        00020000
               contains lines of either a dataset name or a pair of     00030000
               a class and a profile                                    00040000
    Output DD: FILEOU, lists all user IDs, each  each ID with           00050000
               all 'HC'ed dataset and resource names this ID having     00060000
               an authority to access to                                00070000
    optionally, specify GRPEXPND or RSCEXPND or both                    00080000
    if specifying both, it does not matter which argument goes first    00090000
    GRPEXPND is used to list all users in a group;                      00100000
    RSCEXPND is used to list all specific profiles if a profile is      00110000
             a generic one                                              00120000
                                  andrewJ 2008 Mar 31 */                00130000
 /* updated to also put the group id name                               00131000
                                  andrewJ 2008 Apr 01 */                00132000
 /* updated to check the leat authority                                 00132100
                                  andrewJ 2008 Apr 08 */                00133000
 /* updated to take group cics transaction class into consideration     00134000
                                  andrewJ 2008 Apr 28 */                00135000
 /* updated to provide an option: TRNEXPND to specify whether to        00136002
    list all transactions or not                                        00137002
                                  andrewJ 2008 Apr 29 */                00138002
 /* updated to also check if it reaches a section end to prevent        00138107
    the scan from running to far in case there is a '*' specified       00138207
                                  andrewJ 2008 Apr 30 */                00138307
 /* updated to skip 'no entries'                                        00138410
                                  andrewJ 2008 Apr 30 */                00138510
                                                                        00139002
 arg arg1 arg2                                                          00140000
                                                                        00140100
 /* read in all group class data & form an array */     /*20080428*/    00141000
  "execio * diskr grpclass (stem rec. finis"            /*20080428*/    00142000
 j = 0                                                  /*20080428*/    00143000
 grp. = 0                                               /*20080428*/    00144000
 do i = 1 to rec.0                                      /*20080428*/    00145000
    if word(rec.i,1) \= grp.j then                      /*20080428*/    00146000
      do                                                /*20080428*/    00147000
       grp.0 = grp.0 + 1                                /*20080428*/    00148000
       j = j + 1                                        /*20080428*/    00149000
       k = 1                                            /*20080428*/    00149100
      end                                               /*20080428*/    00149200
    grp.j   = word(rec.i,1)                             /*20080428*/    00149300
    grp.j.k = word(rec.i,2)                             /*20080428*/    00149400
    l = 1                                               /*20080429*/    00149504
    do l = 1 to 5                                       /*20080429*/    00149604
      if word(rec.i,l+2) = '' then leave                /*20080429*/    00149704
      else                                              /*20080429*/    00149804
       do                                               /*20080429*/    00149904
          grp.j.k.l = word(rec.i,l+2)                   /*20080429*/    00150004
          grp.j.k.0 = grp.j.k.0 + 1                     /*20080429*/    00150104
       end                                              /*20080429*/    00150204
    end                                                 /*20080429*/    00150304
    grp.j.0 = grp.j.0 + 1                               /*20080428*/    00150400
    k = k + 1                                           /*20080428*/    00150500
 end                                                    /*20080428*/    00150600
                                                                        00150700
 do forever   /* loop for all recs of input file */                     00151000
  "execio 1 diskr filein"                                               00160000
      if rc \= 0  then                                                  00170000
        do                                                              00180000
         if rc =2 then leave                                            00190000
         else                                                           00200000
          do                                                            00210000
           say execname '"EXECIO DISKR" Exit=' rc                       00220000
          end                                                           00230000
        end                                                             00240000
   pull rec                                                             00250000
                                                                        00250100
   gyes = 0                                         /*20080424*/        00251000
                                                                        00252000
   if words(rec) = 2 then  /* from 1 to 2 for the extra auth field*/    00260000
    do                                                                  00270000
      dsn = word(rec,1)                                                 00280000
      lstau = substr(word(rec,2),1,1) /* the least authority to check */00281000
      upper lstau         /* for comparison later */                    00282000
      if lstau = 'R' then lstau = 'V' /*make it larger than U*/         00283000
      call rtn_dataset   /* process dataset profiles */                 00290000
    end                                                                 00300000
   else                                                                 00310000
    do                                                                  00320000
      class = word(rec,1)  /* class name */                             00330000
      rprof = word(rec,2) /* profile name */                            00340000
      lstau = substr(word(rec,3),1,1) /* the least authority to check */00341000
      upper lstau    /* for a comparsion later */                       00342000
      if lstau = 'R' then lstau = 'V' /*make it larger than U*/         00343000
      call rtn_resource  /* process resource profiles */                00350000
    end                                                                 00360000
 end /* end of do forever */                                            00370000
                                                                        00380000
 "execio 0 diskr filein (finis"                                         00390000
 "execio 0 diskw fileou (finis"                                         00400000
                                                                        00410000
 exit 0                                                                 00420000
                                                                        00430000
 rtn_dataset:                                                           00440000
   x = outtrap('prof.')                                                 00450000
   "ld da('"dsn"') ge auth "  /* check authority to the file */         00460000
   x = outtrap('off')                                                   00470000
                                                                        00480000
   do  i = 1 to prof.0                                                  00490000
     if word(prof.i,1) = 'ID' & ,                   /*20080430*/        00491008
        word(prof.i,2) = 'ACCESS' & ,               /*20080430*/        00492008
        word(prof.i,3) = 'CLASS'  & ,               /*20080430*/        00493008
        words(prof.i) > 4 then leave                /*20080430*/        00494008
     call rtn_extract_data                                              00500000
   end /* of do to prof.0 */                                            00510000
 return                                                                 00520000
                                                                        00530000
 rtn_resource: /* routine to process resource profiles */               00540000
   if grp.0  \= 0  then                             /*20080428*/        00542000
    do                                              /*20080428*/        00543000
      do g = 1 to grp.0                             /*20080428*/        00544000
        if class = grp.g then                       /*20080428*/        00545000
         do                                         /*20080424*/        00546000
           gyes = 1                                 /*20080424*/        00547000
           if rprof = '*' then                      /*20080424*/        00548000
            do                                      /*20080424*/        00549000
             x = outtrap('gtrn.')                   /*20080424*/        00549100
             "sr nomask cla("class") "              /*20080424*/        00549200
             x = outtrap('off')                     /*20080424*/        00549300
             do jj = 1 to gtrn.0                    /*20080424*/        00549400
               rprof = word(gtrn.jj,1)              /*20080424*/        00549605
               call rtn_rsc_granule                 /*20080424*/        00549805
             end                                    /*20080424*/        00549905
            end                                     /*20080424*/        00550005
           else call rtn_rsc_granule                /*20080424*/        00550105
           leave                                    /*20080428*/        00550205
         end                                        /*20080424*/        00550305
        else if class < grp.g then leave            /*20080428*/        00550405
      end /* of do to grp.0 */                      /*20080428*/        00550505
    end /* of if grp.0 \=0 */                       /*20080428*/        00550605
                                                    /*20080428*/        00550705
   if gyes = 0 then                                 /*20080428*/        00550805
    do                                              /*20080428*/        00550905
      if arg1 = 'RSCEXPND ' | arg2 = 'RSCEXPND' then                    00551001
       do                                                               00560001
         parse var rprof highname '.' .                                 00570001
         x = outtrap('spec.')                                           00580001
         "sr mask("highname") cla("class") " /* all specific profiles */00590001
         x = outtrap('off')                                             00600001
         do k = 1 to spec.0                                             00610001
           rprof = word(spec.k,1)                                       00620001
           call rtn_rsc_granule                                         00630001
         end                                                            00640001
       end                                                              00650001
      else                                                              00660001
         call rtn_rsc_granule                                           00670001
    end                                             /*20080428*/        00671001
 return                                                                 00680000
                                                                        00690000
 rtn_rsc_granule:                                                       00700000
   x = outtrap('prof.')                                                 00710000
   "rl "class" "rprof" auth "  /* check authority to the file */        00720000
   x = outtrap('off')                                                   00730000
                                                                        00742000
   do  i = 1 to prof.0                                                  00750000
     profile = class                                                    00760000
     dsn     = rprof                                                    00770000
     if word(prof.i,1) = 'ID' & ,                   /*20080430*/        00771007
        word(prof.i,2) = 'ACCESS' & ,               /*20080430*/        00772007
        word(prof.i,3) = 'ACCESS' & ,               /*20080430*/        00772108
        words(prof.i) > 4 then leave                /*20080430*/        00773007
     call rtn_extract_data                                              00780000
   end /* of do to prof.0 */                                            00790000
 return                                                                 00800000
                                                                        00810000
 rtn_extract_data:  /*extract wanted data*/                             00820000
   select                                                               00830000
     when substr(prof.i,1,23) = 'INFORMATION FOR DATASET' then          00840000
         profile = word(prof.i,4)                                       00850000
     when word(prof.i,1) = 'RESOURCES' & ,          /*20080424*/        00851000
          word(prof.i,2) = 'IN'        & ,          /*20080424*/        00852000
          word(prof.i,3) = 'GROUP' then             /*20080424*/        00853000
       do                                           /*20080424*/        00854000
         i = i + 2                                  /*20080424*/        00855000
         tt = 1                                     /*20080424*/        00856000
         trn.0 = 0                                  /*20080424*/        00857000
         do forever                                 /*20080424*/        00858000
           if word(prof.i,1) /= '' then             /*20080424*/        00859000
             do                                     /*20080424*/        00859100
              xxxx = word(prof.i,1)                 /*20080428*/        00859200
              parse var xxxx sysn '.' trnn          /*20080428*/        00859300
              if trnn = '' then trnn = sysn         /*20080429*/        00859404
              if grp.g.0 \= 0 then                  /*20080428*/        00859500
               do                                   /*20080428*/        00859600
                do gg = 1 to grp.g.0                /*20080428*/        00859700
                 if trnn = grp.g.gg then            /*20080428*/        00859800
                  do                                /*20080428*/        00859900
                   unwant = 0                       /*20080429*/        00860004
                   if grp.g.gg.0 \= 0 then          /*20080429*/        00860104
                     do g3  = 1 to grp.g.gg.0       /*20080429*/        00860204
                      parse var grp.g.gg.g3 '-' xxx /*20080429*/        00860304
                      if xxx = sysn then            /*20080429*/        00860404
                        do                          /*20080429*/        00860504
                          unwant = 1                /*20080429*/        00860604
                          leave                     /*20080429*/        00860704
                        end                         /*20080429*/        00860804
                     end                            /*20080429*/        00860904
                   if unwant = 1 then leave         /*20080429*/        00861004
                   trn.tt = xxxx || ','             /*20080428*/        00861100
                   trn.0  = trn.0 + 1               /*20080424*/        00861200
                   tt = tt + 1                      /*20080424*/        00861300
                   leave  /* jump out of the loop*/ /*20080428*/        00861400
                  end                               /*20080428*/        00861500
                 else if trnn < grp.g.gg then leave /*20080428*/        00861600
                end /* of do to  grp.g.0 */         /*20080428*/        00861700
               end                                  /*20080428*/        00861800
              i = i + 1                             /*20080424*/        00861900
             end                                    /*20080424*/        00862000
           else                                     /*20080424*/        00862100
              leave   /* jump out of the loop */    /*20080424*/        00862200
         end /*of forever*/                         /*20080424*/        00862300
       end  /*of when*/                             /*20080424*/        00862400
     when ( word(prof.i,1) = 'ID' | word(prof.i,1) = 'USER')  & ,       00863000
          word(prof.i,2) = 'ACCESS' & ,                                 00870000
          words(prof.i) < 5 then                                        00880000
       do                                                               00890000
         i = i + 2  /* skip this and '------- -------' */               00900000
         do forever                                                     00910000
           if word(prof.i,1) /= '' then                                 00920000
             do                                                         00930000
              if word(prof.i,1) = 'NO' & ,                              00931009
               ( word(prof.i,2) = 'USERS' | ,                           00932009
                 word(prof.i,2) = 'ENTRIES' ) then  /*20080430*/        00933009
                 leave                                                  00950000
              user = word(prof.i,1)                                     00960000
              auth = word(prof.i,2)                                     00970000
              acc = substr(auth,1,1)  /* 1st char */                    00971000
              upper acc     /* in case it is lower*/                    00972000
              if acc = 'R' then acc = 'V' /*make it larger than U*/     00973000
              if acc <= lstau then /* least access right or higher */   00974000
                do                                                      00975000
                  x = outtrap('u_g.')                                   00980000
                  "lg "user" "                                          00990000
                  x = outtrap('off')                                    01000000
                  if word(u_g.1,1) = 'ICH51003I' then                   01010000
                    do                                                  01020000
                     outrec = left(user,8) || ',u       ,' || ,         01030000
                              left(auth,8) || ','|| ,                   01040000
                              left(profile,20) || ','|| dsn             01050000
                     call rtn_output_each              /*20080428*/     01060000
                    end                                                 01080000
                  else                                                  01090000
                    do                                                  01100000
                     outrec = left(user,8) || ',g       ,' || ,         01110000
                              left(auth,8) || ','|| ,                   01120000
                              left(profile,20) || ','|| dsn             01130000
                     call rtn_output_each              /*20080428*/     01131000
                     if arg1 = 'GRPEXPND' | arg2 = 'GRPEXPND' then      01160000
                      do j = 1 to u_g.0                                 01170000
                        if word(u_g.j,2) = 'USE' then                   01180000
                          do                                            01190000
                            outrec = left(word(u_g.j,1),8) || ',' || ,  01200000
                                 left(user,8) || ','|| ,                01210000
                                 left(auth,8) || ','|| ,                01220000
                                 left(profile,20) || ','|| dsn          01230000
                            call rtn_output_each       /*20080428*/     01231000
                          end                                           01260000
                      end /* of grpexpnd do */                          01270000
                    end /* of else */                                   01280000
                 end /* of if acc <= lstau */                           01281000
              i = i + 1                                                 01290000
             end                                                        01300000
           else                                                         01310000
              leave   /* jump out of the loop */                        01320000
         end  /* of do forever*/                                        01330000
       end /* of when */                                                01340000
    otherwise                                                           01350000
   end /* of select */                                                  01360000
 return                                                                 01370000
                                                                        01380000
 rtn_output_each:   /* do the prt, in particular tackle group class*/   01390000
                                                         /*20080428*/   01391000
   if gyes = 1 then                                      /*20080428*/   01400000
    do                                                   /*20080429*/   01400103
     if trn.0 \= 0 & arg2 = 'TRNEXPND' then              /*20080429*/   01400203
       do tt = 1 to trn.0                                /*20080428*/   01401002
         queue outrec || '_' || trn.tt                   /*20080428*/   01401102
         "execio 1 diskw fileou"                         /*20080428*/   01401202
       end                                               /*20080428*/   01401302
     else if trn.0 \= 0 then                             /*20080429*/   01401402
       do                                                /*20080429*/   01401502
         queue outrec || ','                             /*20080429*/   01401602
         "execio 1 diskw fileou"                         /*20080429*/   01401702
       end                                               /*20080429*/   01401802
    end                                                  /*20080429*/   01401903
   else                                                  /*20080428*/   01402002
     do                                                  /*20080428*/   01402102
       queue outrec || ','                               /*20080428*/   01402200
       "execio 1 diskw fileou"                           /*20080428*/   01403000
     end                                                 /*20080428*/   01403100
                                                         /*20080428*/   01404000
 return                                                  /*20080428*/   01410000
