 /* rexx */
 /* Merge OSR ID as well as other privilege ID into a single list */
 /*                                            aj 2008 May 08     */
 /* Add header                                 aj 2008 May 13     */
 /* fix the bug that if the OSR id list already reaches the end   */
 /* the rest ids in system privilege list will not be checked     */
 /*                                            aj 2008 Jun 23     */
 /* Add ROAUDIT for z/os 2.2 new artribute                        */
 /*                                       timwang 2018 Sep 07     */
 /* read in all priv. ids */
 "execio * diskr privilid (stem privil. finis"

 j = 1 /* set the initial value for looping through all OSR priv. ids*/


 queue ' *** Privilege IDs for' mvsvar(sysname) ,
       'on' date()  'at'  time() 'by' sysvar(sysuid) ,
           '*** '
 queue left(' ',10)                             /*20080513*/
 queue right('A---- Audit    ',58)              /*20080513*/
 queue right('-R--- Audit    ',58)              /*20180907*/
 queue right('--S-- Special  ',58)              /*20080513*/
 queue right('---O- Operation',58)              /*20080513*/
 queue right('----0 UID(0)   ',58)              /*20080513*/
 queue left(' ',10)                             /*20080513*/
 queue left('UserID     Owner Name',41) || 'System/OSR Authorities'
 queue left('-',63,'-')                         /*20080513*/
 "execio * diskw idsum"


 Do forever
   "execio 1 diskr userin"
     if rc \= 0 then
       do
         if rc = 2 then leave
         else
          do
           say execname '"EXECIO DISKR" Exit=' rc
          end
       end
    parse pull rec


    if word(rec,1) = '*USER' then iterate


    id = strip(substr(rec,2,8))
    name = strip(substr(rec,11,30))
    attr = substr(rec,41,4)

    if j >  privil.0 then                                 /*20080623*/
     do                                                   /*20080623*/
    /*if attr \= '----' then                                20080623*/
      if attr \= '-----' then                             /*20180907*/
        do                                                /*20080623*/
          queue left(id,10) || ' ' || left(name,30) || ,  /*20080623*/
                ' ' attr || '    '                        /*20080623*/
          "execio 1 diskw idsum "                         /*20080623*/
        end                                               /*20080623*/
      iterate                                             /*20080623*/
     end                                                  /*20080623*/

    do i = j to privil.0
      if strip(privil.i) =  id   then
       do
         queue left(id,10) || ' ' || left(name,30) || ,
               ' ' attr || ' OSR'
         "execio 1 diskw idsum "
         j = i + 1
         leave
       end
      else if strip(privil.i) > id   then
       do
       /*if attr \= '----' then  */
         if attr \= '-----' then                        /*20180907*/
           do
             queue left(id,10) || ' ' || left(name,30) || ,
                   ' ' attr || '    '
             "execio 1 diskw idsum "
           end
         j = i
         leave
       end
      else
       do
       /*if attr \= '----' then */
         if attr \= '-----' then                        /*20180907*/
           do
             queue left(id,10) || ' ' || left(name,30) || ,
                   ' ' attr || '    '
             "execio 1 diskw idsum "
           end
       end
    end /* of do i=  */
 end /* of do forever */

 "execio 0 diskr userin (finis "
 "execio 0 diskw idsum (finis "

 exit 0

