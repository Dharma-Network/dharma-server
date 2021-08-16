function(doc) {
  if(doc.type == "user") {
    emit(doc.nickname, doc.list_of_projects)
  }
}
