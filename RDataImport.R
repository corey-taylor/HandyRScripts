#!/usr/bin/Rscript

#####	Preparation
#	Load libraries

library(plyr)
library(reshape2)

#	Functions

ChangeNames <- function(x) {
    names(x) <- c("PoseID", "Score")
    return(x)
}

fn_sq <- function(x) x^2

#####	Process data
#	Import tables
  
filelist = list.files(pattern="F0*")
dflist = ls(pattern="F0*")
dflistTRANS = ls(pattern="F0*")
for (i in 1:length(filelist)) assign(filelist[i], read.table(filelist[i]))

#	Get rid of columns I don't need and remove extreme scores
#	Using lapply

lst <- mget(ls(pattern='^F\\d+'))	#Add data frames to a list
lst <- lapply(lst, "[", TRUE, c("V2","V7"))	#Only keep columns I want
lst <- lapply(lst, ChangeNames)	#Change column names to "PoseID" and "Score"
lst <- lapply(lst, function(x) x[x$Score<0,])	#Delete scores > 0

#	Write out to data frames

lst <- lapply(seq_along(lst), 
             function(i,x) {assign(paste0(filelist[i]),x[[i]], envir=.GlobalEnv)},
             x=lst)
         
rm(lst, filelist)

#	Generate plots

lst <- mget(ls(pattern='^F\\d+'))	#Add data frames to a list
#hist <- lapply(lst, function(x) hist(x$Score))

#	Transform scores

lst <- lapply(lst, function(x) cbind(x,"Score2"=x$Score^2))    #square scores

#####	Calculate statistics, combine into summary table
#	Mean and std

mean.dat <- lapply(lst, function (x) lapply(x, mean, na.rm=TRUE))	#Calculate mean
mean.dat <- lapply(mean.dat, function(x) { x["PoseID"] <- NULL; x })	#Remove unneeded column (PoseID)
sd.dat <- lapply(lst, function (x) lapply(x, sd, na.rm=TRUE))	#Calculate sd
sd.dat <- lapply(sd.dat, function(x) { x["PoseID"] <- NULL; x })	#Remove unneeded column (PoseID)

#	Generate stats table

stats <- apply(cbind(mean.dat, sd.dat),1,function(x) unname(unlist(x)))	#Combine list results
stats <- as.data.frame(t(stats))	#Transpose
stats$FragID <- rownames(stats)	#Add fragment name column
stats <- rename(stats, c("V1"="MeanScore", "V3"="sdScore","V2"="MeanTRANSScore", "V4"="sdTRANSScore"))
stats$sd2 <- stats$sdScore*2	#Add sd multipled by 2 to get two-sigma
stats$sdTRANS2 <- stats$sdTRANSScore*2	#Add transformed sd multipled by 2 to get two-sigma
stats$ScoreCutoff <- stats$MeanScore-stats$sd2	#Get cut-off score
stats$ScoreTRANSCutoff <- stats$MeanTRANSScore+stats$sdTRANS2	#Get cut-off score for transformed data
stats <- stats[c(5,1,3,6,8,2,4,7,9)]	#Reorder columns

rm(mean.dat, sd.dat)	#Delete not needed lists

#####	Perform cut-off calculations then delete score columns and output to file
#	Untransformed scores

processedScores = lapply(names(lst), 
              function(x){ 
                  cutoffval = subset(stats, FragID %in% x); 
                  subset(lst[[x]], Score < cutoffval$ScoreCutoff)	#By untransformed energy score
              })

processedScores <- lapply(processedScores, "[", TRUE, c("PoseID"))	#Only keep columns I want
processedScores <- as.data.frame(unlist(processedScores))	#	convert to data frame
write.table(processedScores, "processedScores", sep="\t", col.names=FALSE, quote=FALSE, row.names=FALSE)	#output to file
              
#	Transformed scores
              
processedScoresTRANS = lapply(names(lst), 
             function(x){ 
                 cutoffval = subset(stats, FragID %in% x); 
                 subset(lst[[x]], Score2 > cutoffval$ScoreTRANSCutoff)    #By transformed energy score
             })
             
processedScoresTRANS <- lapply(processedScoresTRANS, "[", TRUE, c("PoseID"))	#Only keep columns I want
processedScoresTRANS <- as.data.frame(unlist(processedScoresTRANS))	#	convert to data frame
write.table(processedScoresTRANS, "processedScoresTRANS", sep="\t", col.names=FALSE, quote=FALSE, row.names=FALSE)	#output to file