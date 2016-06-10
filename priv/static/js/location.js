function WebSocketManager(ws){
    this.ws = ws;
    this.handlers = [];
    var self = this;
    this.ws.onmessage = function(evt){
        var evnt = JSON.parse(evt.data)
        for(var h in self.handlers){
            self.handlers[h][1].call(self.handlers[h][0], evnt);
        }
    }
}

WebSocketManager.prototype.add_handler = function(obj, handler){
    this.handlers.push([obj, handler])
}

WebSocketManager.prototype.send = function(message){
    this.ws.send(JSON.stringify(message));
}

function Message(type, data, id){
    this.type = type;
    this.data = data;
    this.id = id;
}

function Location(obj, parent, user_id, websocket){
    this.ackd = false;
    this.data = obj;
    this.ws = websocket;
    this.id = this.data.id;
    this.start = null;
    this.user_id = user_id;
    this.last = {};
    this.events = [];
    this.dom(parent);
    this.graph();
    this.websocket();
}

Location.prototype.dom = function(parent){
    var elem = "<div class=\"location\"> \
                    <img id=\"stream"+this.id+"\"> \
                    <div class=\"messages\" id=\"messages"+this.id+"\"></div> \
                </div>";
    var self = this;
    $(parent).append(elem);
    $("#on"+this.id).click(function(){
        self.on();
    });
    $("#off"+this.id).click(function(){
        self.off();
    });
}

Location.prototype.graph = function(){
    var self = this;
    this.context = cubism.context() // set the cubism context
        .serverDelay(0) // No server delay
        .clientDelay(0) // No client delay
        .step(1000) // step once ever second
        .size(800); // and make the horizon div 960 px wide.

    d3.select("#messages"+this.id).call(function (div) {
        div.append("div")
            .attr("class", "axis")
            .call(self.context.axis().orient("top"));
        div.append("div")
            .attr("class", "rule")
            .call(self.context.rule());
    });

    this.context.on("focus", function (i) {
        self.align_values(i);
    });
}

Location.prototype.align_values = function(i) {
    var self = this;
    d3.selectAll(".value").each(function (index, d, k) {
        for (l = 0; l < self.events.length; l++) {
            if ($(this).text().replace("−", "-") == self.events[l].value) {
                $(this).text(self.events[l].name);
            }
        }
    }).style("right", i == null ? null : self.context.size() - i + 10 + "px");
}

Location.prototype.update_data = function(){
    d3.select("#messages"+this.id).selectAll(".horizon")
        .data(this.events)
        .enter()
        .append("div")
        .attr("class", "horizon")
        .call(this.context.horizon().extent([-20, 20]));
}

Location.prototype.create_metric = function(ev){
    var self = this;
    var values = [],
        value = 0,
        last;
    this.last[ev.type] = ev.value;
    return this.context.metric(function (start, stop, step, callback) {
        start = +start, stop = +stop;
        if (isNaN(last)) last = start;
        while (last < stop) {
            last += step;
            values.push(self.last[ev.type]);
        }
        callback(null, values = values.slice((start - stop) / step)); //And execute the callback function
    }, ev.type);
}

Location.prototype.reset_data = function(){
    console.log("reset data");
    for(var k in this.events){
        this.events[k].values = [];
    }
}

Location.prototype.websocket = function(){
    this.send("location", this.data.data);
    console.log("Location: "+this.id);
    this.ws.add_handler(this, this.onmessage);
}

Location.prototype.onmessage = function(evnt) {
    if(evnt.id != this.id) return;
    if(!this.ackd){
        this.ackd = true;
        this.stream();
    }
    switch(evnt.type){
        case "stats":
            for(var mp in evnt.value){
                var ts = 0;
                var mes = evnt.value[mp];
                for(var ts in evnt.value[mp].data){
                    var ev = evnt.value[mp].data[ts];
                    var tot = 0;
                    for(var k in ev.all){
                        if(ev.all[k]) tot+= ev.all[k];
                    }
                    if(ev.timestamp > ts && tot){
                        if(!(mes.name in this.last)){
                            this.events.push(this.create_metric({type:mes.name, value:tot}));
                            this.update_data();
                        }else{
                            this.last[mes.name] = tot;
                        }
                        ts = ev.timestamp;
                    }
                }
            }
            //this.update_graph();
    }
};

Location.prototype.update_graph = function(ts){
    if (!this.start) this.start = ts;
    var progress = ts - this.start;
    if(progress > 400){
        this.start = ts;
        for(var k in this.last){
            var evs = false;
            for(var e in this.events){
                if(this.events[e].key == k) evs = this.events[e];
            }
            if(!evs){
                evs = {key: k, values: []}
                this.events.push(evs)
            }
            var cp = jQuery.extend({}, this.last[k]);
            cp.x = new Date().getTime()/1000;
            evs.values.push(cp);
            if(evs.values.length > 250) evs.values.shift();
        }
        d3.select('#messages'+this.id+' svg')
            .datum(this.events)
            .call(this.chart);
    }
    var self = this;
    window.requestAnimationFrame(function(ts){self.update_graph(ts)});
}

Location.prototype.send = function(type, data){
    var m = new Message(type, data, this.id);
    this.ws.send(m);
}

Location.prototype.on = function(){
    this.send("light", "on");
}

Location.prototype.off = function(){
    this.send("light", "off");
}

Location.prototype.stream = function(){
    $("#stream"+this.id).attr("src", "/stream?location_id="+this.id+"&user_id="+this.user_id);
}
