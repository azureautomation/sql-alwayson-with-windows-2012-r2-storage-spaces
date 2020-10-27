Sql Alwayson with Windows 2012 R2 Storage Spaces
================================================

            

In 2012 R2 with the cluster feature enabled any storage space objects created from will be automatically clustered by default. 


For Windows 8/Windows Server 2012 or later, use Storage Spaces with a virtual disk configured as a Simple Space. Other types of Space configurations, such as Mirror or Parity, are not recommended in Azure. Set stripe size to 64 KB for OLTP workloads and
 256 KB for data warehousing workloads to avoid performance impact due to partition misalignment. In addition, set column count = number of physical disks


This example script will:


  *  Turn off the automatic clustering of spaces 
  *  Build a simple space out of any locally attached pool(able) disks  
  *  Interleave will be set to 65536 or 262144 
  *  Number of columns will match number of pool able disks attached
 
 


    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
