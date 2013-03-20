args<-commandArgs(trailingOnly = FALSE)

require(ggplot2)

c<-read.csv(args[length(args)-1])

usr<-c$user
nice<-c$nice
sys<-c$sys
iowait<-c$iowait
irq<-c$irq
soft<-c$soft
steal<-c$steal
guest<-c$guest
idle<-c$idle

task_data<-data.frame(Time="", Task="", Value=as.numeric(""))
task_data<-task_data[-1,]

for (i in 1:length(usr)) {
    task_data<-rbind( task_data,
                                  data.frame(Time=as.character(i),
                                             Task="Usr",
                                             Value=as.numeric(usr[i])))
    task_data<-rbind( task_data,
                                  data.frame(Time=as.character(i),
                                             Task="Nice",
                                             Value=as.numeric(nice[i])))
    task_data<-rbind( task_data,
                                  data.frame(Time=as.character(i),
                                             Task="Sys",
                                             Value=as.numeric(sys[i])))
    task_data<-rbind( task_data,
                                  data.frame(Time=as.character(i),
                                             Task="IO Wait",
                                             Value=as.numeric(iowait[i])))
    task_data<-rbind( task_data,
                                  data.frame(Time=as.character(i),
                                             Task="IRQ",
                                             Value=as.numeric(irq[i])))
    task_data<-rbind( task_data,
                                  data.frame(Time=as.character(i),
                                             Task="Soft",
                                             Value=as.numeric(soft[i])))
    task_data<-rbind( task_data,
                                  data.frame(Time=as.character(i),
                                             Task="Steal",
                                             Value=as.numeric(steal[i])))
    task_data<-rbind( task_data,
                                  data.frame(Time=as.character(i),
                                             Task="Guest",
                                             Value=as.numeric(guest[i])))
    task_data<-rbind( task_data,
                                  data.frame(Time=as.character(i),
                                             Task="Idle",
                                             Value=as.numeric(idle[i])))
}

png(filename=args[length(args)],width=800)
options(scipen=20)
ggplot(task_data, aes(x=Time, y=Value, fill=Task, color=Task, group=Task, xlab="",ylab="",xaxt='n')) + geom_area(position = "stack", stat="identity") + ggtitle("Overall CPU Usage") + theme(axis.title.y = element_blank(), axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks = element_blank(), panel.grid.major = element_blank(),panel.grid.minor=element_blank())
dev.off()

