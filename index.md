---
layout: default
title: '本日のTwiplaイベント一覧'
date: 2025-01-17 23:18:34 +0900
---

# 本日のTwiplaイベント一覧

<div id="events"></div>

<script>
  document.addEventListener("DOMContentLoaded", function() {
    fetch('json-ld/twipla_events_2025-01-17.json')
      .then(response => response.json())
      .then(events => {
        const today = new Date().toISOString().split('T')[0];
        const eventsToday = events.filter(event => event.startDate.startsWith(today));
        const eventsContainer = document.getElementById('events');

        if (eventsToday.length === 0) {
          eventsContainer.innerHTML = "<p>本日のイベントはありません。</p>";
        } else {
          eventsToday.forEach(event => {
            const eventElement = document.createElement('div');
            eventElement.innerHTML = `
              <h2>${event.name}</h2>
              <p><strong>リンク:</strong> <a href="${event.url}">${event.url}</a></p>
              <p><strong>日付:</strong> ${event.startDate}</p>
              <p><strong>説明:</strong> ${event.description}</p>
              <p><strong>フライヤー:</strong> <img src="${event.image}" alt="フライヤー"></p>
              <p><strong>場所:</strong> ${event.location.name}</p>
              <p><strong>主催者:</strong> <a href="${event.organizer.url}">${event.organizer.name}</a></p>
            `;
            eventsContainer.appendChild(eventElement);
          });
        }
      })
      .catch(error => {
        console.error('Error fetching events:', error);
      });
  });
</script>