/// <reference types="vite/client"/>

import './app.css'

import { Application } from '@hotwired/stimulus'
import * as Turbo from '@hotwired/turbo'
import { registerControllers } from 'stimulus-vite-helpers'

Turbo.start()
const application = Application.start()
const controllers = import.meta.glob('./controllers/*_controller.ts', { eager: true })
registerControllers(application, controllers)

/* */
