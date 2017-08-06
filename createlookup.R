check.list<-function(genera.list){
  counting.genera<-table(genera.list$genus)
  multi.counts<-names(counting.genera[counting.genera>1])
  bad.genus<-NA
  bad.family<-NA
  for (i in 1:length(unique(multi.counts))){
   now<-filter(genera.list,genus==multi.counts[i])
   if (sum(now$number.of.accepted.species)>0){
     if(!any(now$number.of.accepted.species==0)) message (multi.counts[i])
     out<-filter(now,number.of.accepted.species==0)
     bad.genus<-c(bad.genus,out$genus)
     bad.family<-c(bad.family,out$family)
   }
   if (sum(now$number.of.accepted.species)==0) message(multi.counts[i])
  }
}





getTplVascularPlantFamilies<-function(){
  #get full list of families
  tf<-tpl_families()
  #exclude bryophytes
  #tf<-subset(tf,tf$group!="Bryophytes")
  return(tf)
}

downloadPlantList<-function(familyList){
  path <- "plantListAcceptedNames"
  dir.create(path, FALSE)
  alreadyHaveFile<-dir(path)
  alreadyHave<-sub(".csv","",alreadyHaveFile)
  if(any(!familyList$family%in%alreadyHave)){
    tpl_get(path,family=familyList$family[!familyList$family%in%alreadyHave])
  }
  return(path)
}



get.genera<-function(family, path,tf){
  ah <- read.csv(file.path(path,family), stringsAsFactors=FALSE)
  #
  group<-tf$group[match(ah$Family[1],tf$family)]
  if (nrow(ah)==0) {
    return(NULL)
  }
  not.species <- c("Species.hybrid.marker", "Genus.hybrid.marker", "Infraspecific.epithet")
  tmp <- ah[not.species]
  ah <- ah[apply(tmp == "" | is.na(tmp), 1, all), ]
  if (nrow(ah)==0) {
    return(NULL)
  }

  # not using table(accepted.species$Genus) because it leaves things oddly structured
  accepted.species<-subset(ah,Taxonomic.status.in.TPL=="Accepted")
  n.accepted.species <- tapply(accepted.species$Infraspecific.rank, accepted.species$Genus, length)
  n.total.species <- tapply(ah$Infraspecific.rank, ah$Genus, length)
  n.accepted.species.matched<-n.accepted.species[match(names(n.total.species),names(n.accepted.species))]
  names(n.accepted.species.matched)<-names(n.total.species)
  n.accepted.species.matched[is.na(n.accepted.species.matched)]<-0

  out <- data.frame(family=ah$Family[1],
                    genus=names(n.total.species),
                    group=group,
                    number.of.accepted.species=n.accepted.species.matched,
                    number.of.accepted.and.unresolved.species=n.total.species,
                    stringsAsFactors=FALSE)
  return(out)
}

combineGeneraLists<-function(path,tf){
  out<-lapply(dir(path), get.genera, path,tf)
  tplGenera<-do.call(rbind,out)
  return(tplGenera)
}

patchTPL<-function(tplGenera,additions){
  out<-rbind(tplGenera,additions)
  return(out)
}


matchPlantListFamiliesToApweb<-function(tplGenera){
  apFamilies<-apgFamilies()
  #Some commas come in from apWeb and they cause problems later unless we take them out
  apFamilies$family<-gsub('"',"",apFamilies$family)
  apFamilies$family[apFamilies$family=="Iso&euml;taceae"]<-"Isoëtaceae"
  apFamilies$order<-gsub(',',"",apFamilies$order)
  #currently taxize doesn't parse the synonym versus real familes correctly
  apFamilies$acceptedFamilies<-apFamilies$synonym
  apFamilies$acceptedFamilies[is.na(apFamilies$acceptedFamilies)]<-apFamilies$family[is.na(apFamilies$acceptedFamilies)]
  #fix two spelling mistakes from the plant list, so that they match properly
  tplGenera$family[tplGenera$family=="Dryopteridacae"]<-"Dryopteridaceae"
  tplGenera$family[tplGenera$family=="Apleniaceae"]<-"Aspleniaceae"
  tplGenera$family[tplGenera$family=="Bataceae"]<-"Batidaceae"
  #match to APWeb
  tplGenera$order<-apFamilies$order[match(tplGenera$family,apFamilies$acceptedFamilies)]
  #for families still unmatched, use APWeb's synonomy
  tplGenera$order[is.na(tplGenera$order)]<-apFamilies$order[match(tplGenera$family,apFamilies$family)[is.na(tplGenera$order)]]
  #fixing Vivianiaceae problem
  tplGenera$order[tplGenera$family=="Vivianiaceae"]<-"Geraniales"
  #"Bryophytes" are a problem
  tplGenera$order[tplGenera$group=="Bryophytes"]<-"undeter_peristomate_moss"
  #Sphagnopsida is generally thought to be the basal branch within the mosses
  tplGenera$order[tplGenera$family=="Sphagnaceae"]<-"sphagnopsid_moss"
  #andreaeopsida is the next one
  tplGenera$order[tplGenera$family%in%c("Andreaeobryaceae","Takakiaceae")]<-"andreaeopsid_moss"
  #splitting out the hornworts
  tplGenera$order[tplGenera$family %in% c("Leiosporocerotaceae", "Anthocerotaceae", "Notothyladaceae","Phymatocerotaceae","Dendrocerotaceae")]<-"undetermined_hornwort_order"
  #and the liverworts
  tplGenera$order[tplGenera$family %in% read.delim("source_data/liverwortFamilies.txt",header=FALSE)$V1]<-"undetermined_liverwort_order"
  #temporary: adjusting for a taxize bug
  tplGenera$order[tplGenera$family=="Eriocaulaceae"]<-"Poales"

  #setting up a seperate column with ApWeb synonymy
  tplGenera$apweb.family<-tplGenera$family
  badFamilies<-unique(tplGenera$apweb.family[!tplGenera$apweb.family%in%apFamilies$acceptedFamilies&tplGenera$group!="Bryophytes"&tplGenera$apweb.family%in%apFamilies$family])
  tplGenera$apweb.family[tplGenera$apweb.family%in%badFamilies]<-apFamilies$synonym[match(tplGenera$apweb.family,apFamilies$family)][tplGenera$apweb.family%in%badFamilies]
  tplGenera$apweb.family[tplGenera$apweb.family=="Compositae"]<-"Asteraceae"
  return(tplGenera)
}

fixFernsAndOtherProblems<-function(genera.list, fae, errors){
  #filling in tpl orders for families that apweb misses
  #problems<-unique(genera.list$family[is.na(genera.list$order)])
  #currently only correcting Osmundaceae and Plagiogyriaceae
  genera.list$order[is.na(genera.list$order)]<-fae$order[match(genera.list$family,fae$family)[is.na(genera.list$order)]]

  #this was fixed upstream
  #genera.list$order[genera.list$family=="Cystodiaceae"]<-"Polypodiales"
  #genera.list$family[genera.list$family=="Isoëtaceae"]<-"Isoetaceae"
  #genera.list$order[genera.list$family=="Isoetaceae"]<-"Isoetales"

  # Too many spaces:
  genera.list$order <- gsub("\\s\\s+", " ", genera.list$order)
  # Other standardisation:
  genera.list$order <- title_case(genera.list$order)

  # tpl errors:
  # these errors are genera that occur in multiple families;
  # these appear to be taxonomically unressolved at the moment,
  # to preserve the nestedness of the taxonomy before a formal decision by the IBC
  # we now tried to identify errors in the plant list (or the sources the plant list uses)
  # if no name appeared erroneous, we use the earlier name as canonical in an
  # attempt to follow the botanical code.  This may need to be revisited as things develop.
  #
  ret <- dropTplErrors(genera.list, errors)

  # Sort rows and columns appropriately:
  ret <- ret[c("number.of.accepted.species","number.of.accepted.and.unresolved.species","genus", "family", "apweb.family","order", "group")]
  ret <- ret[order(ret$group,ret$order, ret$family, ret$apweb.family,ret$genus,ret$number.of.accepted.species,ret$number.of.accepted.and.unresolved.species), ]
  rownames(ret) <- NULL

  return(ret)
}

dropTplErrors <- function(genera.list, errors) {
  key <- paste(errors$genus, errors$family, sep="\r")
  i <- match(key, paste(genera.list$genus, genera.list$family, sep="\r"))
  if (any(is.na(i))) {
    msg <- errors[is.na(i),]
    mssg <- paste0("did not find errors in data:\n",
                   paste(msg$family, msg$genus, sep=" / ", collapse="\n"))
    warning(mssg, immediate.=TRUE)
    i <- i[!is.na(i)]
  }

  genera.list[-i, , drop=FALSE]
}

outputFlatFile <- function(genera.list, filename) {
  write.csv(genera.list, filename, row.names=FALSE, quote=FALSE)
}

readHigherOrderTaxonomy <- function(filename, genera.list) {
  d <- read_csv(filename)

  easy <- d[setdiff(names(d), c("X", "family"))]
  easy <- unique(easy[easy$order != "", ])

  hard <- unique(d[d$order == "", setdiff(names(d), "X")])
  i <- match(hard$family, genera.list$family)
  if (any(is.na(i))) {
    stop("higher order taxonomy needs work")
  }
  hard$order <- genera.list$order[i]
  hard <- hard[setdiff(names(hard), "family")]
  hard <- hard[!(hard$order %in% easy$order), ]
  hard <- unique(hard)

  res <- rbind(easy, hard)

  rownames(res) <- res$order
  return(res[names(res) != "order"])
}

packageData <- function(higher_order_taxonomy, filename) {
  save(list=c("higher_order_taxonomy"), file=filename)
}

title_case <- function(x) {
  re <- "(.*)\\b([a-z])(.*)"
  i <- grepl(re, x)
  if (any(i)) {
    x[i] <- paste0(sub(re, "\\1", x[i]),
                   toupper(sub(re, "\\2", x[i])),
                   sub(re, "\\3", x[i]))
    title_case(x)
  }
  x
}

read_csv <- function(...) {
  read.csv(..., stringsAsFactors=FALSE)
}
