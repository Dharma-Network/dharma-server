function (key, values, rereduce) {
    var result = {};
    for (i = 0; i < values.length; i++) {
        if (rereduce) {
            for (const [key, value] of Object.entries(values[i])) {
                if (result[key] === undefined) result[key] = value
                else {
                    result[key]++
                }
            }
        } else {
            values.forEach(dt => {
                date = new Date(dt);
                dt_str = date.toDateString();
                key = dt_str.substring(dt_str.indexOf(" ") + 1);
                if (result[key] === undefined) result[key] = 1
                else result[key]++
            })
        }
    }
    return (result)
}
