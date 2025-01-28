import concatClass from "discourse/helpers/concat-class";
import ChatModalNewMessage from "discourse/plugins/chat/discourse/components/chat/modal/new-message";
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DropdownMenu from "discourse/components/dropdown-menu";
import UserDropdown from "discourse/components/header/user-dropdown";
// import UserStatusMenu from "discourse/components/header/user-dropdown/user-status-bubble";
// import avatar from "discourse/helpers/avatar";
import htmlClass from "discourse/helpers/html-class";
import DAG from "discourse/lib/dag";
import DiscourseURL from "discourse/lib/url";
import { postRNWebviewMessage } from "discourse/lib/utilities";
import Composer from "discourse/models/composer";
import { SCROLLED_UP, UNSCROLLED } from "discourse/services/scroll-direction";
import dIcon from "discourse-common/helpers/d-icon";
import getURL from "discourse-common/lib/get-url";
import DMenu from "float-kit/components/d-menu";

let headerButtons;
resetHeaderButtons();

function resetHeaderButtons() {
  headerButtons = new DAG({ defaultPosition: { before: "auth" } });
  headerButtons.add("auth");
}

export function headerButtonsDAG() {
  return headerButtons;
}

export function clearExtraHeaderButtons() {
  resetHeaderButtons();
}

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
  @service header;
  @tracked previousURL;
  @tracked chat;

  constructor() {
    super(...arguments);
    this.router.on("routeDidChange", this, this.#updatePreviousURL);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.router.off("routeDidChange", this, this.#updatePreviousURL);
  }

  #updatePreviousURL() {
    if (!this.currentRouteChat) {
      this.previousURL = this.router.currentURL;
    }
  }

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

    if (this.showNewChatButton) {
      count += 1;
    }

    // we only show new topic or share, not both at the same time
    if (this.showNewActions || this.showShareButton) {
      count += 1;
    }

    if (this.showDismissButton) {
      count += 1;
    }

    return count;
  }

  get showBackButton() {
    // or limit to this.currentRouteTopic?
    // return this.capabilities.isAppWebview || this.capabilities.isiOSPWA;
    return true;
  }

  get showNewChatButton() {
    return this.chat?.userCanChat;
  }

  get showNewPmButton() {
    return this.can_send_private_messages;
  }

  get showNewTopicButton() {
    return (
      this.currentUser?.can_create_topic && settings.include_new_topic_button
    );
  }

  get showNewActions() {
    return (
      this.showNewTopicButton || this.showNewChatButton || this.showNewPmButton
    );
  }

  get showShareButton() {
    return settings.include_new_topic_button && this.currentRouteTopic;
  }

  get showDismissButton() {
    return !this.currentUser && this.capabilities.isAppWebview;
  }

  @action
  dismiss() {
    postRNWebviewMessage("dismiss", true);
  }

  @action
  goHome() {
    if (this.currentRouteChat) {
      const url = getURL(this.previousURL);
      if (url) {
        DiscourseURL.routeTo(url);
      } else {
        DiscourseURL.routeTo("/");
      }
    } else {
      DiscourseURL.routeTo("/");
    }
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
  goSearch() {
    return DiscourseURL.routeTo("/search");
  }

  @action
  onRegisterApi(api) {
    this.dMenu = api;
  }

  @action
  toggleHamburger() {
    this.appEvents.trigger("header:keyboard-trigger", {
      type: "hamburger",
    });
  }

  @action
  toggleUserMenu() {
    this.appEvents.trigger("header:keyboard-trigger", {
      type: "user",
    });
  }

  @action
  async openNewTopic() {
    await this.dMenu.close();

    this.composer.openNewTopic({
      action: Composer.CREATE_TOPIC,
      draftKey: Composer.NEW_TOPIC_KEY,
      category: this.router.currentRoute?.attributes?.category,
    });
  }

  @action
  async openNewChat() {
    await this.dMenu.close();
    await this.modal.show(ChatModalNewMessage);
  }

  @action
  async openNewPm() {
    await this.dMenu.close();
    this.composer.openNewMessage({});
  }

  get isVisible() {
    return (
      [UNSCROLLED, SCROLLED_UP].includes(
        this.scrollDirection.lastScrollDirection
      ) && !this.composer.isOpen
    );
  }

  get currentRouteHome() {
    const topMenu = this.siteSettings.top_menu.split("|").filter(Boolean);
    const topMenuRouteNames = topMenu.map((item) => `discovery.${item}`);
    return topMenuRouteNames.includes(this.router.currentRoute.name);
  }

  get currentRouteChat() {
    return this.router.currentRoute.name.startsWith("chat.");
  }

  get currentRouteTopic() {
    return this.router.currentRoute.name.startsWith("topic.");
  }

  get currentRouteSearch() {
    return this.router.currentRoute.name.startsWith("full-page-search");
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

    {{! unclear why we place the footer at the top for ipads? }}
    {{#if this.capabilities.isIpadOS}}
      {{htmlClass "footer-nav-ipad"}}
    {{else if this.isVisible}}
      {{htmlClass "footer-nav-visible"}}
    {{/if}}

    <div class={{this.wrapperClassNames}}>
      <div class="footer-nav-widget">
        <span class="footer-nav__item --menu">
          <DButton
            @action={{this.toggleHamburger}}
            @icon="bars"
            class="btn-flat footer-nav__hamburger"
          />
        </span>

        <span class="footer-nav__item --home">
          <DButton
            @action={{this.goHome}}
            @icon="house"
            class={{concatClass
              "btn-flat"
              "footer-nav__home"
              (if this.currentRouteHome "active")
            }}
          />
        </span>

        {{#if this.showNewActions}}
          <span class="footer-nav__item --new">
            <DMenu
              @identifier="new-menu"
              @title="new"
              @icon="plus"
              @class="btn-transparent footer-nav__new-topic"
              @onRegisterApi={{this.onRegisterApi}}
              @modalForMobile={{true}}
            >
              <:content>
                <DropdownMenu as |dropdown|>
                  {{#if this.showNewTopicButton}}
                    <dropdown.item>
                      <DButton
                        @label={{themePrefix "mobile_footer.new_topic"}}
                        @action={{this.openNewTopic}}
                        @icon="far-pen-to-square"
                        class="btn-transparent"
                      />
                    </dropdown.item>
                  {{/if}}

                  {{#if this.showNewChatButton}}
                    <dropdown.item>
                      <DButton
                        @label={{themePrefix "mobile_footer.new_chat"}}
                        @action={{this.openNewChat}}
                        @icon="comment"
                        class="btn-transparent"
                      />
                    </dropdown.item>
                  {{/if}}

                  {{#if this.showNewPmButton}}
                    <dropdown.item>
                      <DButton
                        @label={{themePrefix "mobile_footer.new_pm"}}
                        @action={{this.openNewPm}}
                        @icon="envelope"
                        class="btn-transparent"
                      />
                    </dropdown.item>
                  {{/if}}
                </DropdownMenu>
              </:content>
            </DMenu>
          </span>
        {{/if}}

        {{#if this.showNewChatButton}}
          <span class="footer-nav__item --chat">
            <DButton
              @action={{this.goChat}}
              @icon="d-chat"
              class={{concatClass
                "btn-flat"
                "footer-nav__chat"
                (if this.currentRouteChat "active")
              }}
              @title="footer_nav.chat"
            />
            {{this.chatUnreadIndicator}}
          </span>
        {{/if}}

        {{#if this.currentUser}}
          <span class="footer-nav__item --user">
            <UserDropdown
              @active={{this.header.userVisible}}
              @toggleUserMenu={{this.toggleUserMenu}}
            />
          </span>
        {{/if}}

        {{#if this.showDismissButton}}
          <span class="footer-nav__item --hub">
            <DButton
              @action={{this.dismiss}}
              @icon="fab-discourse"
              @title={{themePrefix "mobile_footer.return_to_hub"}}
              class="btn-transparent no-text"
            />
          </span>
        {{/if}}
      </div>
    </div>
  </template>
}
