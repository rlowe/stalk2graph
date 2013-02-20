require(ggplot2)

csv_data<-read.csv("scratch.csv")

cs<-diff(csv_data$select)
cd<-diff(csv_data$delete)
ci<-diff(csv_data$insert)
cu<-diff(csv_data$update)
cr<-diff(csv_data$replace)
cl<-diff(csv_data$load)
cdm<-diff(csv_data$delete_multi)
cis<-diff(csv_data$insert_select)
cum<-diff(csv_data$update_multi)
crs<-diff(csv_data$replace_select)

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

ggplot(command_counters_data, aes(x=Time, y=Value, fill=Command, color=Command, group=Command)) + geom_area(position = "stack", stat="identity") + ggtitle("MySQL Command Counters")


