function(doc) {
  if(doc.type == "action"){
    date = new Date(doc.closed_at);
    current = new Date();
    year = current.getFullYear() ==  date.getFullYear() ? "last" : date.getFullYear();
    month = current.getMonth() ==  date.getMonth() ? "last" : date.getMonth() + 1;
    day = date.getDate();
    emit([doc.user, year, month, day], 1)
  }
}
