/* tooltip.js */
/* global ysy */
window.ysy = window.ysy || {};
ysy.view = ysy.view || {};
ysy.view.tooltip = $.extend(ysy.view.tooltip, {
  instance: null,
  show: function (className, event, template, out) {
    if (!this.instance) {
      this.instance = new ysy.view.ToolTip().init();
    }
    return this.instance.reset(className, event, template, out);
  },
  changePos: function (event) {
    if (this.instance)
      return this.instance.changePos(event);
  }
});
ysy.view.taskTooltip = $.extend(ysy.view.taskTooltip, {
  timeout: 0,
  $tooltip: null,
  phase: 1,
  /**
   * phase 1 mouse is out
   * phase 2 mouse on, start timer
   * phase 3 tooltip display
   */
  taskTooltipInit: function () {
    var self = this;
    var showTaskTooltip = function (event) {
      /**
       * phase 3 tooltip display
       */
      if (self.phase !== 2) return;
      var task = gantt._pull[gantt.locate(event)];
      if (!task) return;
      self.phase = 3;
      var taskPos = $(event.target).offset();
      self.$tooltip = ysy.view.tooltip.show("gantt-task-tooltip",
          {left: event.pageX, top: taskPos.top + gantt.config.row_height},
          ysy.view.templates.TaskTooltip,
          self.taskTooltipOut(task));
    };

    /**
     * phase 2 mouse on, start timer 2s
     */
    $("#content")
        .on("mouseenter", ".gantt_task_content, .gantt_task_progress, .gantt-task-tooltip-area", function (e) {
          if (self.phase !== 1) return;
          ysy.log.debug("mouseenter", "tooltip");
          self.phase = 2;
          // ysy.log.debug("e.which = "+e.which+" e.button = "+ e.button+" e.buttons = "+ e.buttons);
          if (e.buttons !== 0) return;
          self.bindHiders(e.target);
          self.timeout = setTimeout(function () {
            showTaskTooltip(e)
          }, 1000);
        });

  },
  bindHiders: function (target) {
    target.addEventListener("mouseleave", this.hideTooltip);
    target.addEventListener("mousedown", this.hideTooltip);
    target.addEventListener("mousemove", this.updatePos);
  },
  hideTooltip: function (event) {
    var self = ysy.view.taskTooltip;
    /**
     * set phase 1 mouse out
     */
    self.phase = 1;
    if (self.timeout) {
      clearTimeout(self.timeout);
    }
    if (self.$tooltip) {
      self.$tooltip[0].style.display = "none";//.hide();
      event.target.removeEventListener("mouseleave", this.hideTooltip);
      event.target.removeEventListener("mousedown", this.hideTooltip);
      event.target.removeEventListener("mousemove", this.updatePos);
    }
  },
  updatePos: function (event) {
    if (ysy.view.taskTooltip.phase !== 3) return;
    ysy.view.tooltip.changePos({left: event.pageX});
  },
  taskTooltipOut: function (task) {
    var issue = task.widget.model;
    var problemList = issue.getProblems();
    var columns = [];
    if (issue.milestone) {
      if (issue.isShared) {
        columns = [{
          name: "shared-from",
          label: "Shared from project",
          value: '#' + issue.real_project_id
        }]
      }
      return {
        name: issue.name,
        end_date: issue.start_date.format(gantt.config.date_format),
        columns: columns
      };
    }
    var columnHeads = gantt.config.columns;
    var banned = ["subject", "start_date", "end_date", "due_date"];
    for (var i = 0; i < columnHeads.length; i++) {
      var columnHead = columnHeads[i];
      if (banned.indexOf(columnHead.name) < 0) {
        var html = columnHead.template(task);
        if (!html) continue;
        if (html.indexOf("<") === 0) {
          html = $(html).html();
        }
        columns.push({name: columnHead.name, label: columnHead.label, value: html});
      }
    }
    if (issue.fixed_version_id) {
      var milestone = ysy.data.milestones.getByID(issue.fixed_version_id);
    }
    return {
      name: issue.name,
      start_date: issue.start_date ? issue.start_date.format(gantt.config.date_format) : moment(null),
      end_date: issue.end_date ? issue.end_date.format(gantt.config.date_format) : moment(null),
      milestone: milestone,
      columns: columns,
      problems: problemList
    };
  }
});
ysy.view.ToolTip = function () {
  ysy.view.Widget.call(this);
  this.lastPos = {left: 0, top: 0};
};
ysy.main.extender(ysy.view.Widget, ysy.view.ToolTip, {
  name: "ToolTip",
  init: function () {
    var $target = this.$target = $("<div id='gantt_tooltip' style='display: none'></div>").appendTo("body");
    $target.on("mouseleave", function () {
      $target[0].style.display = "none";
    });
    ysy.view.onRepaint.push($.proxy(this.repaint, this));
    return this;
  },
  reset: function (className, event, template, out) {
    this.className = className;
    this.event = event;
    this.template = template;
    this.outed = out;
    this.repaintRequested = true;
    return this.$target;
  },
  changePos: function (event) {
    if (event.left === undefined) {
      this.lastPos = {left: event.pageX - 5, top: event.pageY - 5};
      this.$target[0].style.cssText = "display: block; left: " + this.lastPos.left + "px; top: " + this.lastPos.top + "px";
      // this.$target.css({left: event.pageX - 5, top: event.pageY - 5});
    } else {
      var changed = false;
      if (Math.abs(this.lastPos.left - event.left) > 5) {
        this.lastPos.left = event.left;
        changed = true;
      }
      if (event.top !== undefined && Math.abs(this.lastPos.top - event.top) > 5) {
        this.lastPos.top = event.top;
        changed = true;
      }
      if (changed) {
        this.$target[0].style.cssText = "display: block; left: " + this.lastPos.left + "px; top: " + this.lastPos.top + "px";
      }
      // this.$target.css({left: event.left, top: event.top});
    }
  },
  _repaintCore: function () {
    this.$target.html(Mustache.render(this.template, this.outed)); // REPAINT
    this.$target[0].style.display = "block";
    this.$target[0].className = 'gantt-tooltip ' + this.className;
    var event = this.event;
    if (event) {
      this.changePos(event);
    }
    return false;
  }
});