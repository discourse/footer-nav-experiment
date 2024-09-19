import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import htmlClass from "discourse/helpers/html-class";
import DiscourseURL from "discourse/lib/url";
import { postRNWebviewMessage } from "discourse/lib/utilities";
import Composer from "discourse/models/composer";
import { SCROLLED_UP, UNSCROLLED } from "discourse/services/scroll-direction";
import dIcon from "discourse-common/helpers/d-icon";

export default class FooterNavExp extends Component {
  @service appEvents;
  @service capabilities;
  @service chatStateManager;
  @service composer;
  @service currentUser;
  @service historyStore;
  @service modal;
  @service router;
  @service scrollDirection;
  @service siteSettings;

  _modalOn() {
    postRNWebviewMessage("headerBg", "rgb(0, 0, 0)");
  }

  _modalOff() {
    postRNWebviewMessage(
      "headerBg",
      document.documentElement.style.getPropertyValue("--header_background")
    );
  }

  @action
  setDiscourseHubHeaderBg(hasAnActiveModal) {
    if (!this.capabilities.isAppWebview) {
      return;
    }

    if (hasAnActiveModal) {
      this._modalOn();
    } else {
      this._modalOff();
    }
  }

  get buttonsLength() {
    let count = 2; // home + hamburger

    if (this.showBackButton) {
      count += 1;
    }

    if (this.showChatButton) {
      count += 1;
    }

    // we only show new topic or share, not both at the same time
    if (this.showNewTopicButton || this.showShareButton) {
      count += 1;
    }

    if (this.showDismissButton) {
      count += 1;
    }

    return count;
  }

  get showBackButton() {
    // or limit to this.currentRouteTopic?
    return (
      (this.historyStore.hasPastEntries || !!document.referrer) &&
      (this.capabilities.isAppWebview || this.capabilities.isiOSPWA)
    );
  }

  get showChatButton() {
    return this.currentUser?.can_chat;
  }

  get showNewTopicButton() {
    return (
      this.currentUser?.can_create_topic &&
      settings.include_new_topic_button &&
      !this.currentRouteTopic &&
      !this.currentRouteChat
    );
  }

  get showShareButton() {
    return settings.include_new_topic_button && this.currentRouteTopic;
  }

  get showDismissButton() {
    return this.capabilities.isAppWebview;
  }

  @action
  dismiss() {
    postRNWebviewMessage("dismiss", true);
  }

  @action
  goHome() {
    if (this.currentRouteHome) {
      document.querySelector(".list-control-toggle-link-trigger").click();
      event.preventDefault();
      return;
    }
    DiscourseURL.routeTo(`/`);
  }

  @action
  goChat() {
    // sourced from plugins/chat/assets/javascripts/discourse/components/chat/header/icon.gjs
    if (this.chatStateManager.isFullPageActive) {
      return DiscourseURL.routeTo("/chat");
    }

    DiscourseURL.routeTo(this.chatStateManager.lastKnownChatURL || "/chat");
  }

  @action
  toggleHamburger() {
    this.appEvents.trigger("header:keyboard-trigger", {
      type: "hamburger",
    });
  }

  @action
  goNewTopic() {
    // If the page has a create-topic button, use it for context sensitive attributes like category
    const createTopicButton = document.querySelector("#create-topic");
    if (createTopicButton) {
      createTopicButton.click();
      return;
    }

    this.composer.open({
      action: Composer.CREATE_TOPIC,
      draftKey: Composer.NEW_TOPIC_KEY,
    });
  }

  @action
  goBack(_, event) {
    window.history.back();
    event.preventDefault();
  }

  get isVisible() {
    return (
      [UNSCROLLED, SCROLLED_UP].includes(
        this.scrollDirection.lastScrollDirection
      ) && !this.composer.isOpen
    );
  }

  get currentRouteHome() {
    const topMenu = this.siteSettings.top_menu.split("|");
    const topMenuRouteNames = topMenu.map((item) => `discovery.${item}`);

    return topMenuRouteNames.includes(this.router.currentRoute.name);
  }

  get currentRouteChat() {
    return this.router.currentRoute.name.startsWith("chat.");
  }

  get currentRouteTopic() {
    return this.router.currentRoute.name.startsWith("topic.");
  }

  get wrapperClassNames() {
    const classes = ["footer-nav"];

    if (this.isVisible) {
      classes.push("visible");
    }

    classes.push(`buttons-${this.buttonsLength}`);

    return classes.join(" ");
  }

  get chatUnreadIndicator() {
    // JIT import because local-dates isn't necessarily enabled
    const ChatIconUnreadIndicator =
      require("discourse/plugins/chat/discourse/components/chat/header/icon/unread-indicator").default;
    return ChatIconUnreadIndicator;
  }
  <template>
    {{this.setDiscourseHubHeaderBg this.modal.activeModal}}

    {{htmlClass "footer-nav-experiment-present"}}

    {{#if this.capabilities.isIpadOS}}
      {{htmlClass "footer-nav-ipad"}}
    {{else if this.isVisible}}
      {{htmlClass "footer-nav-visible"}}
    {{/if}}

    <div class={{this.wrapperClassNames}}>
      <div class="footer-nav-widget">
        {{#if this.showBackButton}}
          <span class="footer-nav__item footer-nav__back-wrapper">
            <DButton
              @action={{this.goBack}}
              @icon="chevron-left"
              class="btn-flat footer-nav__back"
              @forwardEvent={{true}}
            />
          </span>
        {{/if}}

        <span
          class="footer-nav__item footer-nav__home-wrapper
            {{if this.currentRouteHome 'active'}}"
        >
          <DButton
            @action={{this.goHome}}
            @icon="home"
            class="btn-flat footer-nav__home
              {{if this.currentRouteHome 'active'}}"
          />
          {{dIcon "discourse-chevron-expand"}}
        </span>

        {{#if this.showNewTopicButton}}
          <span class="footer-nav__item">
            <DButton
              @action={{this.goNewTopic}}
              @icon="plus-circle"
              class="btn-flat footer-nav__new-topic"
            />
          </span>
        {{/if}}

        {{#if this.showShareButton}}
          <span class="footer-nav__item">
            <DButton
              @action={{this.goShare}}
              @icon="share-from-square"
              class="btn-flat footer-nav__share"
            />
          </span>
        {{/if}}

        {{#if this.showChatButton}}
          <span class="footer-nav__item footer-nav__chat-wrapper">
            <DButton
              @action={{this.goChat}}
              @icon="d-chat"
              class="btn-flat footer-nav__chat
                {{if this.currentRouteChat 'active'}}"
              @title="footer_nav.chat"
            />
            {{this.chatUnreadIndicator}}
          </span>
        {{/if}}

        <span class="footer-nav__item">
          <DButton
            @action={{this.toggleHamburger}}
            @icon="bars"
            class="btn-flat footer-nav__hamburger"
          />
        </span>

        {{#if this.showDismissButton}}
          <span class="footer-nav__item footer-nav__dismiss-wrapper">
            <DButton
              @action={{this.dismiss}}
              @icon="chevron-down"
              class="btn-flat footer-nav__dismiss"
            />
          </span>
        {{/if}}
      </div>
    </div>
  </template>
}
