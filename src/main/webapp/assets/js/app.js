(function () {
  var THEME_KEY = 'expense_ui_theme';
  var DENSITY_KEY = 'expense_ui_density';

  function iconSvg(name) {
    var icons = {
      moon:
        '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M20 14.5A8.5 8.5 0 0 1 9.5 4 8.5 8.5 0 1 0 20 14.5Z" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>',
      sun:
        '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="12" cy="12" r="4.2" stroke="currentColor" stroke-width="1.8"/><path d="M12 2.5V5M12 19v2.5M4.93 4.93l1.77 1.77M17.3 17.3l1.77 1.77M2.5 12H5M19 12h2.5M4.93 19.07l1.77-1.77M17.3 6.7l1.77-1.77" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>'
    };
    return icons[name] || icons.sun;
  }

  function applyTheme(theme) {
    var safeTheme = theme === 'dark' ? 'dark' : 'light';
    var previousTheme = document.documentElement.getAttribute('data-theme');
    document.documentElement.setAttribute('data-theme', safeTheme);
    try {
      localStorage.setItem(THEME_KEY, safeTheme);
    } catch (err) {
      // no-op
    }
    var label = document.querySelector('[data-theme-label]');
    var icon = document.querySelector('[data-theme-icon]');
    if (label) {
      label.textContent = safeTheme === 'dark' ? 'Dark' : 'Light';
    }
    if (icon) {
      icon.innerHTML = safeTheme === 'dark' ? iconSvg('moon') : iconSvg('sun');
    }
    if (previousTheme !== safeTheme) {
      document.dispatchEvent(new CustomEvent('expense-theme-change', { detail: { theme: safeTheme } }));
    }
  }

  function applyDensity(density) {
    var safeDensity = density === 'compact' ? 'compact' : 'comfortable';
    document.documentElement.setAttribute('data-density', safeDensity);
    try {
      localStorage.setItem(DENSITY_KEY, safeDensity);
    } catch (err) {
      // no-op
    }
    document.querySelectorAll('[data-density-value]').forEach(function (btn) {
      btn.classList.toggle('is-active', btn.getAttribute('data-density-value') === safeDensity);
    });
  }

  function bootstrapPreferences() {
    var savedTheme = 'light';
    var savedDensity = 'comfortable';
    try {
      savedTheme = localStorage.getItem(THEME_KEY) || 'light';
      savedDensity = localStorage.getItem(DENSITY_KEY) || 'comfortable';
    } catch (err) {
      // no-op
    }
    applyTheme(savedTheme);
    applyDensity(savedDensity);
  }

  function createDisplayControls() {
    var controlsMarkup =
      '<div class="ui-controls" data-ui-controls>' +
      '<button type="button" class="ui-btn" data-theme-toggle aria-label="Toggle theme">' +
      '<span class="icon-inline" data-theme-icon>' + iconSvg('sun') + '</span>' +
      '<span data-theme-label>Light</span>' +
      '</button>' +
      '<div class="density-switch" role="group" aria-label="UI density">' +
      '<button type="button" class="density-btn" data-density-value="comfortable">Comfort</button>' +
      '<button type="button" class="density-btn" data-density-value="compact">Compact</button>' +
      '</div>' +
      '</div>';

    var navInner = document.querySelector('.nav-inner');
    if (navInner) {
      var navTools = document.createElement('div');
      navTools.className = 'nav-tools';
      navTools.innerHTML = controlsMarkup;
      navInner.appendChild(navTools);
      return;
    }

    var authShell = document.querySelector('.auth-shell');
    if (authShell) {
      var authTools = document.createElement('div');
      authTools.className = 'auth-tools';
      authTools.innerHTML = controlsMarkup;
      document.body.insertBefore(authTools, authShell);
    }
  }

  function wireDisplayControls() {
    var themeToggle = document.querySelector('[data-theme-toggle]');
    if (themeToggle) {
      themeToggle.addEventListener('click', function () {
        var current = document.documentElement.getAttribute('data-theme');
        applyTheme(current === 'dark' ? 'light' : 'dark');
      });
    }

    document.querySelectorAll('[data-density-value]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        applyDensity(btn.getAttribute('data-density-value'));
      });
    });
  }

  function ensureTableSections(table) {
    if (!table.tHead && table.rows.length > 0) {
      var thead = table.createTHead();
      thead.appendChild(table.rows[0]);
    }
    if (!table.tBodies.length) {
      table.createTBody();
    }
    var body = table.tBodies[0];
    Array.prototype.slice.call(table.children).forEach(function (child) {
      if (child.tagName && child.tagName.toUpperCase() === 'TR') {
        body.appendChild(child);
      }
    });
  }

  function getTableTitle(table) {
    var panel = table.closest('.panel');
    if (!panel) {
      return 'entries';
    }
    var heading = panel.querySelector('h2, h3');
    if (!heading) {
      return 'entries';
    }
    heading.classList.add('is-sticky-title');
    return (heading.textContent || 'entries').trim();
  }

  function updateTableFilterState(table, query, colIndex, valueFilter, emptyState, countNode) {
    var body = table.tBodies[0];
    if (!body) {
      return;
    }
    var rows = Array.prototype.slice.call(body.rows);
    var visible = 0;
    rows.forEach(function (row) {
      var cells = Array.prototype.slice.call(row.cells);
      if (!cells.length) {
        return;
      }
      var hay = '';
      var cellValue = '';
      if (colIndex >= 0 && colIndex < cells.length) {
        cellValue = (cells[colIndex].textContent || '').trim();
        hay = cellValue.toLowerCase();
      } else {
        hay = (row.textContent || '').toLowerCase();
      }
      var matchSearch = !query || hay.indexOf(query) !== -1;
      var matchValue = valueFilter === '__all' || colIndex < 0 || cellValue === valueFilter;
      var match = matchSearch && matchValue;
      // Some table styles can interfere with `display`; `hidden` is a stronger signal.
      row.hidden = !match;
      row.style.display = match ? '' : 'none';
      if (match) {
        visible += 1;
      }
    });

    if (countNode) {
      countNode.textContent = visible + ' shown';
    }
    if (emptyState) {
      emptyState.classList.toggle('is-visible', visible === 0);
    }
  }

  function setupSmartTables() {
    var tables = document.querySelectorAll('.table-wrap table');
    tables.forEach(function (table, tableIndex) {
      if (table.getAttribute('data-enhanced') === 'true') {
        return;
      }
      table.setAttribute('data-enhanced', 'true');
      ensureTableSections(table);

      var title = getTableTitle(table);
      var wrap = table.closest('.table-wrap');
      if (!wrap) {
        return;
      }
      wrap.classList.add('table-wrap-enhanced');

      var tool = document.createElement('div');
      tool.className = 'table-tools';
      tool.innerHTML =
        '<div class="table-search">' +
        '<input type="search" autocomplete="off" placeholder="Search ' + title + '" data-table-search="' + tableIndex + '">' +
        '</div>' +
        '<div class="table-filter">' +
        '<select data-table-col="' + tableIndex + '" aria-label="Filter column"><option value="all">All Columns</option></select>' +
        '<select data-table-value="' + tableIndex + '" aria-label="Filter value" disabled><option value="__all">All Values</option></select>' +
        '<button type="button" class="btn ghost table-reset" data-table-reset="' + tableIndex + '">Reset</button>' +
        '<span class="table-count" data-table-count="' + tableIndex + '"></span>' +
        '</div>';
      wrap.parentNode.insertBefore(tool, wrap);

      var select = tool.querySelector('select');
      var valueSelect = tool.querySelector('[data-table-value]');
      var resetBtn = tool.querySelector('[data-table-reset]');
      var search = tool.querySelector('input[type="search"]');
      var countNode = tool.querySelector('[data-table-count]');
      var emptyState = document.createElement('div');
      emptyState.className = 'table-filter-empty';
      emptyState.textContent = 'No rows match this filter.';
      wrap.parentNode.insertBefore(emptyState, wrap.nextSibling);

      Array.prototype.slice.call(table.tHead.rows[0].cells).forEach(function (th, idx) {
        var txt = (th.textContent || '').trim();
        if (!txt) {
          return;
        }
        var opt = document.createElement('option');
        opt.value = String(idx);
        opt.textContent = txt;
        select.appendChild(opt);
      });

      function populateValueOptions(colIndex) {
        valueSelect.innerHTML = '<option value="__all">All Values</option>';
        if (colIndex < 0) {
          valueSelect.disabled = true;
          return;
        }

        var seen = {};
        var values = [];
        Array.prototype.slice.call(table.tBodies[0].rows).forEach(function (row) {
          if (!row.cells[colIndex]) {
            return;
          }
          var value = (row.cells[colIndex].textContent || '').trim();
          if (value && !seen[value]) {
            seen[value] = true;
            values.push(value);
          }
        });

        values.sort(function (a, b) {
          return a.localeCompare(b, undefined, { sensitivity: 'base', numeric: true });
        });

        values.forEach(function (value) {
          var opt = document.createElement('option');
          opt.value = value;
          opt.textContent = value;
          valueSelect.appendChild(opt);
        });
        valueSelect.disabled = false;
      }

      function runFilter() {
        var query = (search.value || '').toLowerCase().trim();
        var colValue = select.value;
        var colIndex = colValue === 'all' ? -1 : parseInt(colValue, 10);
        var valueFilter = valueSelect.disabled ? '__all' : valueSelect.value;
        updateTableFilterState(table, query, colIndex, valueFilter, emptyState, countNode);
      }

      populateValueOptions(-1);
      search.addEventListener('input', runFilter);
      select.addEventListener('change', function () {
        var colIndex = select.value === 'all' ? -1 : parseInt(select.value, 10);
        populateValueOptions(colIndex);
        runFilter();
      });
      valueSelect.addEventListener('change', runFilter);
      resetBtn.addEventListener('click', function () {
        search.value = '';
        select.value = 'all';
        populateValueOptions(-1);
        runFilter();
      });
      runFilter();
    });
  }

  function showBootLoader() {
    var loader = document.createElement('div');
    loader.className = 'app-loader';
    loader.setAttribute('aria-hidden', 'true');
    loader.innerHTML =
      '<div class=\"app-loader-card\">' +
      '<div class=\"sk-row w-78\"></div>' +
      '<div class=\"sk-row w-90\"></div>' +
      '<div class=\"sk-row w-62\"></div>' +
      '<div class=\"sk-row w-48\"></div>' +
      '</div>';

    document.body.appendChild(loader);
    requestAnimationFrame(function () {
      loader.classList.add('is-visible');
    });

    setTimeout(function () {
      loader.classList.add('is-hide');
      setTimeout(function () {
        if (loader.parentNode) {
          loader.parentNode.removeChild(loader);
        }
      }, 240);
    }, 520);
  }

  function updateClocks() {
    var nodes = document.querySelectorAll('[data-live-clock]');
    var now = new Date();
    var value = now.toLocaleString('en-IN', {
      hour12: true,
      year: 'numeric',
      month: 'short',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
    nodes.forEach(function (node) {
      node.textContent = value;
    });
  }

  function setupFlash() {
    var flashes = document.querySelectorAll('[data-flash]');
    flashes.forEach(function (flash) {
      setTimeout(function () {
        flash.style.transition = 'opacity 0.35s ease, transform 0.35s ease';
        flash.style.opacity = '0';
        flash.style.transform = 'translateY(-4px)';
      }, 4200);
      setTimeout(function () {
        if (flash.parentNode) {
          flash.parentNode.removeChild(flash);
        }
      }, 4700);
    });
  }

  function setupTabs() {
    var triggers = document.querySelectorAll('[data-tab-target]');
    if (!triggers.length) {
      return;
    }

    triggers.forEach(function (trigger) {
      trigger.addEventListener('click', function () {
        var targetId = trigger.getAttribute('data-tab-target');
        document.querySelectorAll('[data-tab-pane]').forEach(function (pane) {
          pane.classList.remove('is-active');
        });
        document.querySelectorAll('[data-tab-target]').forEach(function (btn) {
          btn.classList.remove('is-active');
        });
        var target = document.getElementById(targetId);
        if (target) {
          target.classList.add('is-active');
        }
        trigger.classList.add('is-active');
      });
    });
  }

  function setupCountUp() {
    var items = document.querySelectorAll('[data-count-up]');
    items.forEach(function (item) {
      var target = parseFloat(item.getAttribute('data-count-up'));
      if (isNaN(target)) {
        return;
      }
      var decimals = (target.toString().split('.')[1] || '').length;
      var steps = 32;
      var current = 0;
      var step = target / steps;
      var tick = 0;
      var id = setInterval(function () {
        tick += 1;
        current += step;
        if (tick >= steps) {
          current = target;
          clearInterval(id);
        }
        item.textContent = current.toFixed(decimals);
      }, 18);
    });
  }

  function setupCardMotion() {
    var cards = document.querySelectorAll('.module-card, .metric-card');
    cards.forEach(function (card) {
      card.addEventListener('mousemove', function (event) {
        if (window.matchMedia('(max-width: 900px)').matches) {
          return;
        }
        var rect = card.getBoundingClientRect();
        var x = (event.clientX - rect.left) / rect.width;
        var y = (event.clientY - rect.top) / rect.height;
        var tiltX = (0.5 - y) * 2.2;
        var tiltY = (x - 0.5) * 2.2;
        card.style.transform = 'rotateX(' + tiltX.toFixed(2) + 'deg) rotateY(' + tiltY.toFixed(2) + 'deg) translateY(-2px)';
      });

      card.addEventListener('mouseleave', function () {
        card.style.transform = '';
      });
    });
  }

  function setupStickySections() {
    document.querySelectorAll('.page-head').forEach(function (head) {
      head.classList.add('is-sticky-section');
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    bootstrapPreferences();
    createDisplayControls();
    wireDisplayControls();
    applyTheme(document.documentElement.getAttribute('data-theme'));
    applyDensity(document.documentElement.getAttribute('data-density'));
    setupStickySections();
    showBootLoader();
    updateClocks();
    setInterval(updateClocks, 1000);
    setupFlash();
    setupTabs();
    setupCountUp();
    setupCardMotion();
    setupSmartTables();
  });
})();
