args<-commandArgs(trailingOnly = FALSE)

print(Sys.time())

require(ggplot2)

command_counters_data<-read.csv(args[length(args)-1])

cs<-diff(command_counters_data$select)
cd<-diff(command_counters_data$delete)
ci<-diff(command_counters_data$insert)
cu<-diff(command_counters_data$update)
cr<-diff(command_counters_data$replace)
cl<-diff(command_counters_data$load)
cdm<-diff(command_counters_data$delete_multi)
cis<-diff(command_counters_data$insert_select)
cum<-diff(command_counters_data$update_multi)
crs<-diff(command_counters_data$replace_select)

command_counters_data<-data.frame(Time="", Command="", Value=as.numeric(""))
command_counters_data<-command_counters_data[-1,]

print(Sys.time())
for (i in 1:length(cs)) {
print(Sys.time())
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Select",
                                             Value=cs[i]))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Delete",
                                             Value=cd[i]))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Insert",
                                             Value=ci[i]))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Update",
                                             Value=cu[i]))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Replace",
                                             Value=cr[i]))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Load",
                                             Value=cl[i]))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Delete Multi",
                                             Value=cdm[i]))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Insert Select",
                                             Value=cis[i]))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Update Multi",
                                             Value=cum[i]))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Replace Select",
                                             Value=crs[i]))
}


print(command_counters_data)
print(Sys.time())

png(filename=args[length(args)],width=800)
options(scipen=20)
ggplot(command_counters_data, aes(x=Time, y=Value, fill=Command, color=Command, group=Command, xlab="",ylab="",xaxt='n')) + geom_area(position = "stack", stat="identity") + ggtitle("MySQL Command Counters") + theme(axis.title.y = element_blank(), axis.title.x = element_blank(), axis.text.x = element_blank(), axis.ticks = element_blank(), panel.grid.major = element_blank(),panel.grid.minor=element_blank())
dev.off()

print(Sys.time())

