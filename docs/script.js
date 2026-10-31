const topButton = document.querySelector(".back-top");
const tocLinks = [...document.querySelectorAll("aside a")];
const sections = tocLinks
  .map(link => document.querySelector(link.hash))
  .filter(Boolean);

function setActiveSection(id) {
  for (const link of tocLinks) {
    const active = link.hash === `#${id}`;
    link.classList.toggle("active", active);
    if (active) link.setAttribute("aria-current", "location");
    else link.removeAttribute("aria-current");
  }
}

const sectionObserver = new IntersectionObserver(entries => {
  const visible = entries.find(entry => entry.isIntersecting);
  if (visible) setActiveSection(visible.target.id);
}, {
  rootMargin: "-100px 0px -65% 0px"
});

sections.forEach(section => sectionObserver.observe(section));

const heroObserver = new IntersectionObserver(([entry]) => {
  topButton.classList.toggle("show", !entry.isIntersecting);
});

heroObserver.observe(document.querySelector(".hero"));

setActiveSection(sections[0].id);
