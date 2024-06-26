# Health Check Tool for z/OS using RACF

This is a Health Check tool to complement the TRT Testing Tool for z/OS 
accounts who use RACF as their security server.

How to use this tool?

1. Upload in Binary mode the following two files to an LRECL=80, Fix-BLocked
   sequential dataset on the mainframe:
   SYS1.HCTOOL.LMD.xmit 
   ANDREWJ.HCTOOL.PARMLIB.xmit
   
   Use the TSO 'RECEIVE INDSN'command to create the two partitioned datasets:
   SYS1.HCTOOL.LMD     (by just pressing the enter key following the RECEIVE
                        command)  
   SYS1.HCTOOL.PARMLIB (by specifying DSN=SYS1.HCTOOL.PARMLIB following the
                        RECEIVE command)

   To successfully implement this tool, these two datasets are supposedly to be 
   in place now:
   SYS1.HCTOOL.LMD
   SYS1.HCTOOL.PARMLIB

2. If you are running the job for the first time, please submit JCLALLOC.
   three new files for output data will be created. They are:
   userid.HCTOOL.IDS4OSR and
   userid.HCTOOL.IDSUM   and
   userid.HCTOOL.OSR24ID, where userid is the TSO ID you are using now.

3. Edit the HC member to include the OSR entries reflecting what OSR resources
   particular to the system you are now running.
   Please refer to those marked as 'HC:' in your CSD or ITCS manual:
   'A1. z/OS, OS/390 and MVS Platforms with RACF Technical Specification.

   Also edit GRPCLASS member to reflect newer CICS categories 1 and 2 control
   on transaction IDs, if you run CICS and use GCICSTRN class 


4. Submit JCLRUN to produce output data to the 2 datasets:
   userid.HCTOOL.IDS4OSR
          holds OSR entries, with the information about what user IDs
          are able to access each particular entry at what privilege levels
   userid.HCTOOL.OSRS4ID
          holds privilege user ID entries, with the information about what OSR
          entries, a particular ID is able to access at what privilege levels

5. A 2nd job will be created by JCLRUN with a JOB Name as the SYSNAME of the
   system you are running on. To check the result of the running, please
   issue 'H sysname', where sysname is the system name of the sytem.

6. Step 5 of the 2nd job will transmit 2 files to another system account whose
   node name and ID are specified in step 1 of JCLRUN.
   The current node name and ID are 'VMSYSTEM.VMUSER'. if a diff. one is used,
   just replace 'TAIVM1.RESETMVS' accordingly.
   If you don't need this function, just leave it alone.

7. The 2 files transmitted are:
   1. a summary of all user IDs (except group IDs) having OSR privilege.
   2. userid.HCTOOL.OSRS4ID

8. With regard to the group class: GCICSTRN:
   1. If you want to list all controlled transaction ID information , please
      specify 'TRNEXPND' as the 2nd argument to Step 1 of JCLRUN


