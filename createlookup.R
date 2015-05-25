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
  accepted.species<-subset(ah,Taxonomic.status.in.TPL=="Accepted")
  group<-tf$group[match(accepted.species$Family[1],tf$family)]
  if (nrow(accepted.species)==0) {
    return(NULL)
  }
  not.species <- c("Species.hybrid.marker", "Genus.hybrid.marker", "Infraspecific.epithet")
  tmp <- accepted.species[not.species]
  accepted.species <- accepted.species[apply(tmp == "" | is.na(tmp), 1, all), ]
  if (nrow(accepted.species)==0) {
    return(NULL)
  }

  # not using table(accepted.species$Genus) because it leaves things oddly structured
  n.species <- tapply(accepted.species$Infraspecific.rank, accepted.species$Genus, length)

  out <- data.frame(family=accepted.species$Family[1],
                    genus=names(n.species),
                    group=group,
                    number.of.species=n.species,
                    stringsAsFactors=FALSE)
  return(out)
}

combineGeneraLists<-function(path,tf){
  out<-lapply(dir(path), get.genera, path,tf)
  tplGenera<-do.call(rbind,out)
  return(tplGenera)
}

matchPlantListFamiliesToApweb<-function(tplGenera){
  apFamilies<-apgFamilies()
  #Some commas come in from apWeb and they cause problems later unless we take them out
  apFamilies$family<-gsub('"',"",apFamilies$family)
  apFamilies$order<-gsub(',',"",apFamilies$order)
  #currently taxize doesn't parse the synonym versus real familes correctly
  apFamilies$acceptedFamilies<-apFamilies$synonym
  apFamilies$acceptedFamilies[is.na(apFamilies$acceptedFamilies)]<-apFamilies$family[is.na(apFamilies$acceptedFamilies)]
  #fix two spelling mistakes from the plant list, so that they match properly
  tplGenera$family[tplGenera$family=="Dryopteridacae"]<-"Dryopteridaceae"
  tplGenera$family[tplGenera$family=="Apleniaceae"]<-"Aspleniaceae"
  tplGenera$order<-apFamilies$order[match(tplGenera$family,apFamilies$acceptedFamilies)]
  tplGenera$order[is.na(tplGenera$order)]<-apFamilies$order[match(tplGenera$family,apFamilies$family)[is.na(tplGenera$order)]]
  tplGenera$order[tplGenera$group=="Bryophytes"]<-"unknown.bryophte.order"
  return(tplGenera)
}

fixFernsAndOtherProblems<-function(genera.list, fae, errors){
  #problems<-unique(genera.list$family[is.na(genera.list$order)])
  #currently only correcting Osmundaceae and Plagiogyriaceae
  genera.list$order[is.na(genera.list$order)]<-fae$order[match(genera.list$family,fae$family)[is.na(genera.list$order)]]
  #changing ë to e for now.  Encoding is a nightmare
  genera.list$family[genera.list$family=="Isoëtaceae"]<-"Isoetaceae"
  genera.list$order[genera.list$family=="Isoetaceae"]<-"Isoetales"

  # Rename some families with modern names; commented out for now so that our family names match other tpl lists
  #genera.list$family[genera.list$family == "Leguminosae"] <- "Fabaceae"
  #genera.list$family[genera.list$family == "Compositae"] <- "Asteraceae"

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
  ret <- ret[c("number.of.species","genus", "family", "order", "group")]
  ret <- ret[order(ret$group,ret$order, ret$family, ret$genus,ret$number.of.species), ]
  rownames(ret) <- NULL

  return(ret)
}

dropTplErrors <- function(genera.list, errors) {
  key <- paste(errors$genus, errors$family, sep="\r")
  i <- match(key, paste(genera.list$genus, genera.list$family, sep="\r"))
  if (any(is.na(i))) {
    msg <- errors[is.na(i)]
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
  res[names(res) != "order"]
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
