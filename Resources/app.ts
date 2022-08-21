/// <reference types="vite/client"/>

import './app.css'

import { Application } from '@hotwired/stimulus'
import * as Turbo from '@hotwired/turbo'
import { registerControllers } from 'stimulus-vite-helpers'

const application = Application.start()
const controllers = import.meta.glob('./controllers/*_.ts', { eager: true })
registerControllers(application, controllers)
