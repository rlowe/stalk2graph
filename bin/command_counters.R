require(ggplot2)

command_counters_data<-read.csv("command_counters.csv")

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

for (i in 1:length(cs)) {
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Select",
                                             Value=as.numeric(cs[i])))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Delete",
                                             Value=as.numeric(cd[i])))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Insert",
                                             Value=as.numeric(ci[i])))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Update",
                                             Value=as.numeric(cu[i])))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Replace",
                                             Value=as.numeric(cr[i])))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Load",
                                             Value=as.numeric(cl[i])))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Delete Multi",
                                             Value=as.numeric(cdm[i])))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Insert Select",
                                             Value=as.numeric(cis[i])))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Update Multi",
                                             Value=as.numeric(cum[i])))
    command_counters_data<-rbind( command_counters_data,
                                  data.frame(Time=as.character(i),
                                             Command="Replace Select",
                                             Value=as.numeric(crs[i])))
}

jpeg('command_counters.jpg')
ggplot(command_counters_data, aes(x=Time, y=Value, fill=Command, color=Command, group=Command, xaxt='n')) + geom_area(position = "stack", stat="identity") + ggtitle("MySQL Command Counters")
dev.off()

